#!/usr/bin/env python3
"""
tag_whole_bible.py - Scripture Emotional & Contemplative Tagging Pipeline

Processes Bible chapters from the free static Free Use Bible API (helloao.org),
pre-filters candidate verses using fast heuristics, tags them via Gemini Flash
(gemini-2.5-flash via google-genai SDK) with rate limiting (15 RPM free tier),
maintains an atomic chapter-level checkpoint, and exports standalone quotes to
Supabase CSVs (`supabase_verses.csv` and `supabase_verse_translations.csv`).
"""

import argparse
import csv
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Literal, Optional, Tuple

# Try importing google-genai and pydantic
try:
    from google import genai
    from google.genai import types
    from pydantic import BaseModel, Field
    HAS_GOOGLE_GENAI = True
except ImportError:
    HAS_GOOGLE_GENAI = False

# High-comfort and wisdom books prioritized for emotional contemplation
PRIORITY_BOOKS = [
    "PSA", "PRO", "ECC", "ISA", "LAM", "MAT",
    "JHN", "ROM", "2CO", "PHP", "JAS", "1PE"
]

# Aliases for book codes (e.g. PHI -> PHP for Philippians, common names to USFM codes)
BOOK_CODE_ALIASES = {
    "PHI": "PHP",
    "PHIL": "PHP",
    "PHILIPPIANS": "PHP",
    "PSALM": "PSA",
    "PSALMS": "PSA",
    "PROVERBS": "PRO",
    "ECCLESIASTES": "ECC",
    "ISAIAH": "ISA",
    "LAMENTATIONS": "LAM",
    "MATTHEW": "MAT",
    "JOHN": "JHN",
    "ROMANS": "ROM",
    "JAMES": "JAS",
    "1PETER": "1PE",
    "1PET": "1PE",
    "2PETER": "2PE",
    "2PET": "2PE",
    "1CORINTHIANS": "1CO",
    "1COR": "1CO",
    "2CORINTHIANS": "2CO",
    "2COR": "2CO",
    "HEBREWS": "HEB",
    "REVELATION": "REV",
    "GENESIS": "GEN",
}

# Standard 66-book canon fallback chapter counts if helloao books.json is unavailable
CANON_CHAPTER_COUNTS = {
    "GEN": 50, "EXO": 40, "LEV": 27, "NUM": 36, "DEU": 34,
    "JOS": 24, "JDG": 21, "RUT": 4,  "1SA": 31, "2SA": 24,
    "1KI": 22, "2KI": 25, "1CH": 29, "2CH": 36, "EZR": 10,
    "NEH": 13, "EST": 10, "JOB": 42, "PSA": 150, "PRO": 31,
    "ECC": 12, "SNG": 8,  "ISA": 66, "JER": 52, "LAM": 5,
    "EZK": 48, "DAN": 12, "HOS": 14, "JOL": 3,  "AMO": 9,
    "OBA": 1,  "JON": 4,  "MIC": 7,  "NAM": 3,  "HAB": 3,
    "ZEP": 3,  "HAG": 2,  "ZEC": 14, "MAL": 4,  "MAT": 28,
    "MRK": 16, "LUK": 24, "JHN": 21, "ACT": 28, "ROM": 16,
    "1CO": 16, "2CO": 13, "GAL": 6,  "EPH": 6,  "PHP": 4,
    "COL": 4,  "1TH": 5,  "2TH": 3,  "1TI": 6,  "2TI": 4,
    "TIT": 3,  "PHM": 1,  "HEB": 13, "JAS": 5,  "1PE": 5,
    "2PE": 3,  "1JN": 5,  "2JN": 1,  "3JN": 1,  "JUD": 1,
    "REV": 22,
}

VALID_STAGES = {"gloomy", "growing", "bright", "humble"}

STAGE_CATEGORY_MAP = {
    "gloomy": ("Comfort in Heavy Seasons", "Morning Pause"),
    "growing": ("Steadfast Hope & Growth", "Daily Walk"),
    "bright": ("Joy & Grateful Praise", "Morning Light"),
    "humble": ("Quiet Trust & Humility", "Still Reflection"),
}


def is_genealogy(text: str) -> bool:
    """
    Check if a verse is a pure genealogy or ancestral list to skip.
    Crucially preserves theological and spiritual verses referencing the Son of God,
    Son of Man, sons of light, sons of the kingdom, etc.
    """
    clean = text.strip()

    # 1. Obvious genealogical header/markers
    if re.search(r"\b(?:the\s+)?(?:book|record)\s+of\s+(?:the\s+)?genealogy\b", clean, re.IGNORECASE):
        return True
    if re.search(r"\bthese\s+are\s+the\s+generations\s+of\b", clean, re.IGNORECASE):
        return True
    if re.search(r"\bbegat\b", clean, re.IGNORECASE):
        return True
    if re.search(r"\b(?:was|became)\s+the\s+father\s+of\b", clean, re.IGNORECASE):
        return True
    if re.search(r"\bthese\s+(?:were|are)\s+the\s+sons\s+of\b", clean, re.IGNORECASE):
        return True

    # 2. Ancestry chains ("the son of A, the son of B...") like Luke 3
    son_matches = re.findall(r"\b(?:the\s+)?son\s+of\b", clean, re.IGNORECASE)
    if len(son_matches) >= 2:
        return True

    # 3. Single "the son of" or "the sons of":
    # If it refers to divine, Messianic, or spiritual sonship, it is NOT a genealogy
    theological_sonship = re.search(
        r"\b(?:the\s+)?(?:son|sons)\s+of\s+(?:god|man|the\s+most\s+high|the\s+living\s+god|the\s+father|the\s+blessed|david|light|the\s+day|the\s+resurrection)\b",
        clean,
        re.IGNORECASE
    )
    if theological_sonship:
        return False

    # 4. Check for genealogical "the son of [Person]" in historical records
    if re.search(r"\b(?:which\s+was\s+)?the\s+son\s+of\s+[A-Z]", clean):
        return True

    return False


def is_boundary_list(text: str) -> bool:
    """
    Check if a verse is a geographical boundary listing (e.g. Joshua 15-19 tribal allotments).
    Preserves comfort/proverbial verses mentioning borders/boundaries (e.g. Psalm 147:14).
    """
    clean = text.strip()

    if re.search(
        r"\b(?:and\s+)?(?:the|its)\s+(?:border|boundary)\s+(?:went|extended|turned|ran|passed|reached|proceeded|skirted|went\s+up|went\s+down|went\s+out)\b",
        clean,
        re.IGNORECASE
    ):
        return True
    if re.search(r"\band\s+(?:the\s+)?border\s+went\s+up\s+to\b", clean, re.IGNORECASE):
        return True
    if re.search(r"\bthis\s+(?:is|was)\s+the\s+inheritance\s+of\s+the\s+tribe\b", clean, re.IGNORECASE):
        return True
    if re.search(r"\baccording\s+to\s+their\s+clans,?\s+this\s+was\s+the\s+allotment\b", clean, re.IGNORECASE):
        return True

    return False


if HAS_GOOGLE_GENAI:
    class VerseTagging(BaseModel):
        id: str
        is_standalone_quote: bool
        primary_stage: Literal["gloomy", "growing", "bright", "humble"] = Field(
            description="Must be exactly one of 'gloomy', 'growing', 'bright', 'humble'"
        )
        mood_tags: List[str] = Field(description="2 to 4 lowercase tags, e.g. ['comfort', 'brokenhearted']")
        humble_reflection_eng: str = Field(
            default="",
            description="Gentle, empathetic 1-2 sentence reflection only when is_standalone_quote is true, else empty string",
        )

    class BatchTaggingResult(BaseModel):
        items: List[VerseTagging]


def normalize_book_code(book: str) -> str:
    """Normalize book code string to uppercase 3-letter USFM standard."""
    cleaned = book.strip().upper()
    return BOOK_CODE_ALIASES.get(cleaned, cleaned)


def fetch_json(url: str, max_retries: int = 3, timeout: int = 15) -> Optional[Dict[str, Any]]:
    """Fetch JSON from a remote URL with retry backoff."""
    for attempt in range(max_retries):
        try:
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "BibleGloryTaggingBot/1.0 (free; open-source-devotional)"}
            )
            with urllib.request.urlopen(req, timeout=timeout) as response:
                if response.status == 200:
                    data = response.read().decode("utf-8")
                    return json.loads(data)
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            if attempt == max_retries - 1:
                print(f"[WARN] HTTP error fetching {url}: {e.code} {e.reason}", file=sys.stderr)
            time.sleep(1.5 * (attempt + 1))
        except Exception as e:
            if attempt == max_retries - 1:
                print(f"[WARN] Network error fetching {url}: {e}", file=sys.stderr)
            time.sleep(1.5 * (attempt + 1))
    return None


def get_book_chapters(translation: str = "BSB") -> Dict[str, int]:
    """Fetch chapter count per book from helloao.org books.json, with fallback to canon."""
    url = f"https://bible.helloao.org/api/{translation}/books.json"
    data = fetch_json(url)
    if data and "books" in data and isinstance(data["books"], list):
        result = {}
        for b in data["books"]:
            book_id = b.get("id")
            num_chapters = b.get("numberOfChapters")
            if book_id and isinstance(num_chapters, int):
                result[book_id] = num_chapters
        if result:
            return result
    return CANON_CHAPTER_COUNTS.copy()


def extract_verse_text_from_content(content_pieces: Any) -> str:
    """Recursively extract and format plain text from helloao verse content fragments."""
    if isinstance(content_pieces, str):
        return content_pieces.strip()
    if isinstance(content_pieces, dict):
        if "text" in content_pieces and isinstance(content_pieces["text"], str):
            return content_pieces["text"].strip()
        if "content" in content_pieces:
            return extract_verse_text_from_content(content_pieces["content"])
        return ""
    if not isinstance(content_pieces, list):
        return ""

    parts = []
    for piece in content_pieces:
        if isinstance(piece, str):
            parts.append(piece.strip())
        elif isinstance(piece, dict):
            if "text" in piece and isinstance(piece["text"], str):
                parts.append(piece["text"].strip())
            elif "content" in piece:
                sub_text = extract_verse_text_from_content(piece["content"])
                if sub_text:
                    parts.append(sub_text)

    # Assemble fragments with clean spacing around punctuation
    result = []
    for part in parts:
        if not part:
            continue
        if result and not re.match(r"^[.,!?;:’'\)\]\}]", part):
            result.append(" ")
        result.append(part)
    return "".join(result).strip()


def fetch_chapter_verses(book: str, chapter: int, translation: str = "BSB") -> List[Dict[str, Any]]:
    """Fetch a chapter from helloao API and extract all verses."""
    norm_book = normalize_book_code(book)
    url = f"https://bible.helloao.org/api/{translation}/{norm_book}/{chapter}.json"
    data = fetch_json(url)
    if not data or "chapter" not in data:
        return []

    chapter_obj = data["chapter"]
    content = chapter_obj.get("content", [])
    verses = []

    if isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and item.get("type") == "verse":
                verse_num = item.get("number")
                if verse_num is not None:
                    raw_text = extract_verse_text_from_content(item.get("content", []))
                    if raw_text:
                        verses.append({
                            "id": f"{norm_book}.{chapter}.{verse_num}",
                            "book": norm_book,
                            "chapter": int(chapter),
                            "verse": int(verse_num),
                            "text": raw_text,
                        })

    # Fallback to chapter['verses'] if present
    if not verses and "verses" in chapter_obj and isinstance(chapter_obj["verses"], dict):
        for v_num_str, v_data in chapter_obj["verses"].items():
            try:
                v_num = int(v_num_str)
            except ValueError:
                continue
            text = ""
            if isinstance(v_data, str):
                text = v_data.strip()
            elif isinstance(v_data, dict):
                text = str(v_data.get("text", "")).strip()
            if text:
                verses.append({
                    "id": f"{norm_book}.{chapter}.{v_num}",
                    "book": norm_book,
                    "chapter": int(chapter),
                    "verse": v_num,
                    "text": text,
                })

    verses.sort(key=lambda v: v["verse"])
    return verses


def prefilter_verse(text: str) -> Tuple[bool, str]:
    """
    Fast local heuristic filter.
    Returns (should_skip, reason).
    """
    clean_text = text.strip()

    # Rule 1: Skip verses shorter than 35 characters
    if len(clean_text) < 35:
        return True, "too short (<35 chars)"

    # Rule 2: Pure genealogies ("begat", "the son of", etc.)
    if is_genealogy(clean_text):
        return True, "genealogy"

    # Rule 3: Boundary lists ("and the border went up to", etc.)
    if is_boundary_list(clean_text):
        return True, "boundary list"

    return False, ""


def heuristic_fallback_tag(verse: Dict[str, Any]) -> Dict[str, Any]:
    """
    Graceful rule-based emotional and contemplative tagger used when Gemini API
    key is absent or offline.
    """
    text = verse["text"].lower()
    vid = verse["id"]
    book = verse["book"]

    # Keyword dictionaries
    gloomy_kw = ["brokenhearted", "crushed", "grief", "sorrow", "downcast", "weep",
                 "tears", "mourn", "darkness", "trouble", "distress", "pit", "heavy",
                 "afflicted", "despair", "cry out", "groan", "sigh"]
    growing_kw = ["patient", "wait", "endure", "steadfast", "sanctif", "discipline",
                  "seek", "path", "guide", "learn", "strength", "hope", "instruct",
                  "command", "walk", "statute", "perseverance"]
    bright_kw = ["rejoice", "joy", "glad", "praise", "sing", "light", "delight",
                 "thanks", "bless", "victory", "triumph", "exalt", "radiant"]
    humble_kw = ["humble", "contrite", "meek", "fear of the lord", "lowly", "dust",
                 "quiet", "trust", "simplicity", "breath", "frail", "gentle", "mercy"]

    scores = {
        "gloomy": sum(2 for k in gloomy_kw if k in text),
        "growing": sum(2 for k in growing_kw if k in text),
        "bright": sum(2 for k in bright_kw if k in text),
        "humble": sum(2 for k in humble_kw if k in text),
    }

    # Wisdom books skew toward humble/growing/bright
    if book in ("PSA", "PRO", "ECC"):
        scores["humble"] += 1
    if book in ("ROM", "PHP", "JAS"):
        scores["growing"] += 1

    best_stage = max(scores, key=lambda s: scores[s])
    if scores[best_stage] == 0:
        best_stage = "growing"

    # Determine if standalone quote
    is_standalone = True
    # If verse starts with narrative dialogue connectors, it may not be standalone
    if re.match(r"^(and he said|then he said|so they|and they went|after these things)", text):
        is_standalone = False

    # Extract mood tags
    tags = []
    if best_stage == "gloomy":
        tags = ["comfort", "brokenhearted", "heavy-day"]
    elif best_stage == "growing":
        tags = ["growth", "steadfast", "hope", "patience"]
    elif best_stage == "bright":
        tags = ["joy", "praise", "radiant", "peace"]
    else:
        tags = ["humility", "quiet-trust", "reverence", "peace"]

    tags = tags[:3]

    # Generate reflection
    reflection = ""
    if is_standalone:
        if best_stage == "gloomy":
            reflection = "Feeling heartbroken does not mean you are forgotten. God draws closest in the quietest, heaviest moments."
        elif best_stage == "growing":
            reflection = "Growth rarely happens in a hurry. Allow patience to do its steady, gentle work in your heart today."
        elif best_stage == "bright":
            reflection = "Let gratitude lighten your spirit today, holding joy with an open, humble hand."
        else:
            reflection = "True peace begins when we let go of having to know every answer, resting simply in God's care."

    return {
        "id": vid,
        "is_standalone_quote": is_standalone,
        "primary_stage": best_stage,
        "mood_tags": tags,
        "humble_reflection_eng": reflection,
    }


def tag_batch_with_gemini(
    client: Any,
    batch_verses: List[Dict[str, Any]],
    rate_limit_delay: float = 4.0,
    max_retries: int = 4
) -> List[Dict[str, Any]]:
    """
    Send candidate verses in a batch of up to 40 verses to Gemini Flash (gemini-2.5-flash)
    using Structured JSON Output.
    """
    prompt_items = [{"id": v["id"], "text": v["text"]} for v in batch_verses]
    prompt = f"""You are a contemplative Bible scholar and emotional companion.
Analyze each of the following candidate Bible verses.

For each verse:
1. `id`: Must match the provided verse ID exactly.
2. `is_standalone_quote`: boolean. Set to true ONLY if the verse is meaningful, comforting, humble, or encouraging entirely on its own without needing surrounding narrative context. Verses that are incomplete thoughts, purely historical/ceremonial details, or dialogue lacking universal spiritual weight must be false.
3. `primary_stage`: Exactly one of ["gloomy", "growing", "bright", "humble"]:
   - "gloomy": brokenheartedness, sorrow, grief, heavy seasons, lament, loneliness, darkness.
   - "growing": patience, sanctification, discipline, gradual healing, steadfastness, hope through trial.
   - "bright": joy, gratitude, thanksgiving, praise, peace, renewed strength, grace.
   - "humble": quiet trust, reverence, meekness, smallness before God, resting in limits.
4. `mood_tags`: An array of 2 to 4 lowercase tags (e.g., ["comfort", "brokenhearted", "heavy-day"]).
5. `humble_reflection_eng`: If `is_standalone_quote` is true, write a gentle, non-arrogant, empathetic 1-2 sentence reflection. Never scold, preach, or speak down. If `is_standalone_quote` is false, provide an empty string.

Verses to analyze:
{json.dumps(prompt_items, indent=2)}
"""

    config = types.GenerateContentConfig(
        response_mime_type="application/json",
        response_schema=BatchTaggingResult,
        temperature=0.2,
    )

    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
                config=config,
            )

            # Polite pacing to respect 15 RPM free tier
            time.sleep(rate_limit_delay)

            raw_text = response.text or ""
            data = json.loads(raw_text)

            # Unpack items from either a dict or list
            raw_items = []
            if isinstance(data, dict):
                raw_items = data.get("items") or data.get("verses") or []
            elif isinstance(data, list):
                raw_items = data

            # Build result map
            result_map = {}
            for item in raw_items:
                if not isinstance(item, dict):
                    continue
                v_id = item.get("id")
                if not v_id:
                    continue

                stage = str(item.get("primary_stage", "growing")).lower().strip()
                if stage not in VALID_STAGES:
                    stage = "growing"

                raw_tags = item.get("mood_tags") or []
                if isinstance(raw_tags, list):
                    tags = [str(t).lower().strip() for t in raw_tags if str(t).strip()]
                else:
                    tags = [stage]
                if len(tags) < 2:
                    tags.append(stage)
                tags = tags[:4]

                is_quote = bool(item.get("is_standalone_quote", False))
                reflection = str(item.get("humble_reflection_eng") or "").strip()
                if not is_quote:
                    reflection = ""

                result_map[v_id] = {
                    "id": v_id,
                    "is_standalone_quote": is_quote,
                    "primary_stage": stage,
                    "mood_tags": tags,
                    "humble_reflection_eng": reflection,
                }

            # Assemble in original batch order
            output = []
            for v in batch_verses:
                v_id = v["id"]
                if v_id in result_map:
                    output.append(result_map[v_id])
                else:
                    # Fallback if model missed a verse
                    output.append(heuristic_fallback_tag(v))
            return output

        except Exception as e:
            err_str = str(e)
            is_rate_limit = "429" in err_str or "RESOURCE_EXHAUSTED" in err_str
            wait_time = (2 ** (attempt + 2)) if is_rate_limit else (attempt + 2) * 3
            print(f"[WARN] Gemini API call attempt {attempt + 1}/{max_retries} failed: {e}. Retrying in {wait_time}s...", file=sys.stderr)
            time.sleep(wait_time)

    print(f"[ERROR] Gemini batch failed after {max_retries} attempts. Falling back to heuristic tagging for this batch.", file=sys.stderr)
    return [heuristic_fallback_tag(v) for v in batch_verses]


def load_checkpoint(checkpoint_path: Path) -> Tuple[set, Dict[str, Dict[str, Any]]]:
    """Load existing checkpoint progress."""
    if not checkpoint_path.exists():
        return set(), {}

    try:
        with open(checkpoint_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            completed_chapters = set(data.get("completed_chapters", []))
            tagged_verses = data.get("tagged_verses", {})
            return completed_chapters, tagged_verses
    except Exception as e:
        print(f"[WARN] Failed to load checkpoint {checkpoint_path}: {e}", file=sys.stderr)
        return set(), {}


def save_checkpoint(
    checkpoint_path: Path,
    completed_chapters: set,
    tagged_verses: Dict[str, Dict[str, Any]]
) -> None:
    """Save checkpoint atomically to disk."""
    checkpoint_path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = checkpoint_path.with_suffix(".tmp")
    data = {
        "completed_chapters": sorted(list(completed_chapters)),
        "total_tagged_verses": len(tagged_verses),
        "last_updated": datetime.now(timezone.utc).isoformat(),
        "tagged_verses": tagged_verses,
    }
    with open(temp_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    os.replace(temp_path, checkpoint_path)


def export_supabase_csvs(
    output_dir: Path,
    tagged_verses: Dict[str, Dict[str, Any]]
) -> Tuple[int, Path, Path]:
    """
    Export all `is_standalone_quote == true` rows to:
    - `supabase_verses.csv` (id, book, chapter, verse, primary_stage, mood_tags, category, sub_tag)
    - `supabase_verse_translations.csv` (verse_id, lang_code, text, reflection)
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    verses_csv_path = output_dir / "supabase_verses.csv"
    trans_csv_path = output_dir / "supabase_verse_translations.csv"

    # Filter quotes (robust against boolean or string representations)
    standalone_verses = [
        v for v in tagged_verses.values()
        if v.get("is_standalone_quote") is True or str(v.get("is_standalone_quote", "")).lower() == "true"
    ]

    # Sort deterministically
    def sort_key(v):
        return (v.get("book", ""), int(v.get("chapter", 0)), int(v.get("verse", 0)))
    standalone_verses.sort(key=sort_key)

    # 1. Write supabase_verses.csv
    # Format mood_tags as Postgres array literal: {tag1,tag2,tag3}
    with open(verses_csv_path, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
        writer.writerow([
            "id", "book", "chapter", "verse",
            "primary_stage", "mood_tags", "category", "sub_tag"
        ])
        for v in standalone_verses:
            stage = v.get("primary_stage", "growing")
            default_cat, default_sub = STAGE_CATEGORY_MAP.get(stage, ("Daily Walk", "Reflection"))
            category = v.get("category") or default_cat
            sub_tag = v.get("sub_tag") or default_sub
            tags = v.get("mood_tags") or [stage]
            # Format PostgreSQL array literal {tag1,tag2}
            escaped_tags = [t.replace('"', '\\"') for t in tags]
            pg_array = "{" + ",".join(escaped_tags) + "}"

            writer.writerow([
                v["id"],
                v["book"],
                v["chapter"],
                v["verse"],
                stage,
                pg_array,
                category,
                sub_tag,
            ])

    # 2. Write supabase_verse_translations.csv
    with open(trans_csv_path, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
        writer.writerow(["verse_id", "lang_code", "text", "reflection"])
        for v in standalone_verses:
            reflection = v.get("humble_reflection_eng") or ""
            writer.writerow([
                v["id"],
                "eng",
                v.get("text", ""),
                reflection,
            ])

    return len(standalone_verses), verses_csv_path, trans_csv_path


def process_chapter(
    book: str,
    chapter: int,
    translation: str,
    gemini_client: Optional[Any],
    batch_size: int = 40,
    rate_limit_delay: float = 4.0,
    use_heuristics_only: bool = False,
) -> List[Dict[str, Any]]:
    """Process a single chapter: fetch, pre-filter, batch tag, and return tagged entries."""
    raw_verses = fetch_chapter_verses(book, chapter, translation)
    if not raw_verses:
        return []

    tagged_chapter_results = []
    candidate_verses = []

    # 1. Pre-filter verses
    for v in raw_verses:
        should_skip, reason = prefilter_verse(v["text"])
        if should_skip:
            tagged_chapter_results.append({
                "id": v["id"],
                "book": v["book"],
                "chapter": v["chapter"],
                "verse": v["verse"],
                "text": v["text"],
                "is_standalone_quote": False,
                "primary_stage": "growing",
                "mood_tags": ["filtered"],
                "humble_reflection_eng": "",
                "filter_reason": reason,
            })
        else:
            candidate_verses.append(v)

    if not candidate_verses:
        return tagged_chapter_results

    # 2. Batch tag candidate verses (batches of up to 40)
    for i in range(0, len(candidate_verses), batch_size):
        batch = candidate_verses[i:i + batch_size]
        if gemini_client is not None and not use_heuristics_only:
            tagged_batch = tag_batch_with_gemini(
                gemini_client,
                batch,
                rate_limit_delay=rate_limit_delay,
            )
        else:
            tagged_batch = [heuristic_fallback_tag(bv) for bv in batch]

        # Merge verse metadata (text, book, chapter, verse)
        batch_map = {bv["id"]: bv for bv in batch}
        for tagged in tagged_batch:
            v_id = tagged["id"]
            orig = batch_map.get(v_id, {})
            stage = tagged.get("primary_stage", "growing")
            cat, sub = STAGE_CATEGORY_MAP.get(stage, ("Daily Walk", "Reflection"))
            full_entry = {
                "id": v_id,
                "book": orig.get("book", normalize_book_code(book)),
                "chapter": orig.get("chapter", chapter),
                "verse": orig.get("verse", 1),
                "text": orig.get("text", ""),
                "is_standalone_quote": tagged.get("is_standalone_quote", False),
                "primary_stage": stage,
                "mood_tags": tagged.get("mood_tags", []),
                "humble_reflection_eng": tagged.get("humble_reflection_eng", ""),
                "category": cat,
                "sub_tag": sub,
            }
            tagged_chapter_results.append(full_entry)

    tagged_chapter_results.sort(key=lambda r: r["verse"])
    return tagged_chapter_results


def build_book_plan(
    target_book: Optional[str],
    target_chapter: Optional[int],
    books_arg: Optional[str],
    all_books_map: Dict[str, int]
) -> List[Tuple[str, int]]:
    """Build the ordered list of (book, chapter) tuples to process."""
    plan = []

    # Case 1: Specific book and chapter
    if target_book:
        norm_b = normalize_book_code(target_book)
        num_chapters = all_books_map.get(norm_b, CANON_CHAPTER_COUNTS.get(norm_b, 1))
        if target_chapter is not None:
            return [(norm_b, target_chapter)]
        else:
            return [(norm_b, ch) for ch in range(1, num_chapters + 1)]

    # Case 2: Priority list or explicit comma-separated list
    book_order = []
    if books_arg:
        upper_arg = books_arg.strip().upper()
        if upper_arg == "ALL":
            # Priority first, then remaining books in canon order
            book_order = [b for b in PRIORITY_BOOKS if b in all_books_map]
            remaining = [b for b in all_books_map if b not in book_order]
            book_order.extend(remaining)
        elif upper_arg in ("PRIORITY", "DEFAULT", "HIGH_COMFORT"):
            book_order = [b for b in PRIORITY_BOOKS if b in all_books_map]
        else:
            raw_codes = [b.strip() for b in books_arg.split(",") if b.strip()]
            book_order = [normalize_book_code(c) for c in raw_codes]
    else:
        # Default: priority books first, then scan remaining
        book_order = [b for b in PRIORITY_BOOKS if b in all_books_map]
        remaining = [b for b in all_books_map if b not in book_order]
        book_order.extend(remaining)

    for b in book_order:
        num_chapters = all_books_map.get(b, CANON_CHAPTER_COUNTS.get(b, 1))
        for ch in range(1, num_chapters + 1):
            plan.append((b, ch))

    return plan


def init_gemini_client(api_key: Optional[str]) -> Tuple[Optional[Any], bool]:
    """Initialize Gemini client if SDK and key are available."""
    resolved_key = (
        api_key or
        os.environ.get("GEMINI_API_KEY") or
        os.environ.get("GOOGLE_API_KEY")
    )

    # Check .env file if available
    if not resolved_key:
        env_file = Path(".env")
        if env_file.exists():
            try:
                with open(env_file, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line.startswith("GEMINI_API_KEY="):
                            resolved_key = line.split("=", 1)[1].strip().strip('"').strip("'")
                            break
                        elif line.startswith("GOOGLE_API_KEY="):
                            resolved_key = line.split("=", 1)[1].strip().strip('"').strip("'")
                            break
            except Exception:
                pass

    if not HAS_GOOGLE_GENAI:
        print("[INFO] `google-genai` SDK is not installed. Running in heuristic fallback mode.", file=sys.stderr)
        return None, False

    if not resolved_key:
        print("[INFO] GEMINI_API_KEY not found in environment or .env. Running in heuristic fallback mode.", file=sys.stderr)
        print("[INFO] Provide GEMINI_API_KEY in environment or pass --api-key to use gemini-2.5-flash.", file=sys.stderr)
        return None, False

    try:
        client = genai.Client(api_key=resolved_key)
        print("[INFO] Successfully initialized Gemini client with `gemini-2.5-flash`.")
        return client, True
    except Exception as e:
        print(f"[WARN] Failed to initialize Gemini client ({e}). Running in heuristic fallback mode.", file=sys.stderr)
        return None, False


def main():
    parser = argparse.ArgumentParser(
        description="Tag Bible chapters into emotional & contemplative stages and export to Supabase CSVs."
    )
    parser.add_argument("--book", type=str, default=None, help="Process a single book (e.g., PSA, PRO, PHI).")
    parser.add_argument("--chapter", type=int, default=None, help="Process a single chapter (requires --book).")
    parser.add_argument("--books", type=str, default=None, help="Books to process ('ALL' or comma-separated list).")
    parser.add_argument("--translation", type=str, default="BSB", help="Translation code: BSB or ENGWEBP (default: BSB).")
    parser.add_argument("--api-key", type=str, default=None, help="Gemini API Key (or set GEMINI_API_KEY).")
    parser.add_argument("--batch-size", type=int, default=40, help="Verses per Gemini API request (default: 40).")
    parser.add_argument("--rate-limit-delay", type=float, default=4.0, help="Delay between batches in seconds (default: 4.0).")
    parser.add_argument("--output-dir", type=str, default="scripts", help="Directory for checkpoint and CSV output.")
    parser.add_argument("--force", action="store_true", help="Reprocess chapters even if already in checkpoint.")
    parser.add_argument("--heuristic-only", action="store_true", help="Force heuristic tagging without Gemini API calls.")

    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    checkpoint_path = output_dir / "checkpoint_tagged_verses.json"

    # 1. Initialize Gemini client or fallback
    gemini_client, is_gemini_active = init_gemini_client(args.api_key)
    if args.heuristic_only:
        is_gemini_active = False
        gemini_client = None

    # 2. Load checkpoint
    completed_chapters, tagged_verses = load_checkpoint(checkpoint_path)
    print(f"[CHECKPOINT] Loaded {len(completed_chapters)} completed chapters and {len(tagged_verses)} tagged verses.")

    # 3. Discover books and chapter plan
    all_books_map = get_book_chapters(args.translation)
    plan = build_book_plan(args.book, args.chapter, args.books, all_books_map)
    print(f"[PLAN] Scheduled {len(plan)} chapters to scan (Translation: {args.translation.upper()}).")

    chapters_processed_this_run = 0

    # 4. Process each chapter
    for book, chapter in plan:
        chap_key = f"{book}.{chapter}"
        if not args.force and chap_key in completed_chapters:
            # Already completed
            continue

        print(f"\n[RUN] Processing {chap_key}...")
        results = process_chapter(
            book=book,
            chapter=chapter,
            translation=args.translation,
            gemini_client=gemini_client,
            batch_size=args.batch_size,
            rate_limit_delay=args.rate_limit_delay,
            use_heuristics_only=(not is_gemini_active),
        )

        if not results:
            print(f"[WARN] No verses returned for {chap_key}. Moving on.")
            continue

        quotes_count = 0
        for entry in results:
            tagged_verses[entry["id"]] = entry
            if entry.get("is_standalone_quote"):
                quotes_count += 1

        completed_chapters.add(chap_key)
        chapters_processed_this_run += 1

        # 5. Save checkpoint after EVERY single chapter
        save_checkpoint(checkpoint_path, completed_chapters, tagged_verses)

        # 6. Update CSV exports after each chapter so data is immediately available
        total_quotes, verses_csv, trans_csv = export_supabase_csvs(output_dir, tagged_verses)
        print(f"[SAVED] {chap_key} complete ({len(results)} verses, {quotes_count} standalone quotes).")
        print(f"[STATUS] Checkpoint saved. Total Standalone Quotes in CSVs: {total_quotes}")

    # Final summary export
    total_quotes, verses_csv, trans_csv = export_supabase_csvs(output_dir, tagged_verses)
    print("\n" + "=" * 60)
    print("TAGGING COMPLETE")
    print(f"Total Chapters in Checkpoint : {len(completed_chapters)}")
    print(f"Total Verses Scanned         : {len(tagged_verses)}")
    print(f"Standalone Quotes Exported   : {total_quotes}")
    print(f"Verses CSV                   : {verses_csv.resolve()}")
    print(f"Verse Translations CSV       : {trans_csv.resolve()}")
    print("=" * 60)


if __name__ == "__main__":
    main()
