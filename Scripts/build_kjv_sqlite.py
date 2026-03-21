#!/usr/bin/env python3

import argparse
import csv
import sqlite3
from pathlib import Path


BOOKS = [
    (1, "Gen", "Genesis", 1, "OT"),
    (2, "Exod", "Exodus", 2, "OT"),
    (3, "Lev", "Leviticus", 3, "OT"),
    (4, "Num", "Numbers", 4, "OT"),
    (5, "Deut", "Deuteronomy", 5, "OT"),
    (6, "Josh", "Joshua", 6, "OT"),
    (7, "Judg", "Judges", 7, "OT"),
    (8, "Ruth", "Ruth", 8, "OT"),
    (9, "1 Sam", "1 Samuel", 9, "OT"),
    (10, "2 Sam", "2 Samuel", 10, "OT"),
    (11, "1 Kgs", "1 Kings", 11, "OT"),
    (12, "2 Kgs", "2 Kings", 12, "OT"),
    (13, "1 Chr", "1 Chronicles", 13, "OT"),
    (14, "2 Chr", "2 Chronicles", 14, "OT"),
    (15, "Ezra", "Ezra", 15, "OT"),
    (16, "Neh", "Nehemiah", 16, "OT"),
    (17, "Esth", "Esther", 17, "OT"),
    (18, "Job", "Job", 18, "OT"),
    (19, "Ps", "Psalms", 19, "OT"),
    (20, "Prov", "Proverbs", 20, "OT"),
    (21, "Eccl", "Ecclesiastes", 21, "OT"),
    (22, "Song", "Song of Solomon", 22, "OT"),
    (23, "Isa", "Isaiah", 23, "OT"),
    (24, "Jer", "Jeremiah", 24, "OT"),
    (25, "Lam", "Lamentations", 25, "OT"),
    (26, "Ezek", "Ezekiel", 26, "OT"),
    (27, "Dan", "Daniel", 27, "OT"),
    (28, "Hos", "Hosea", 28, "OT"),
    (29, "Joel", "Joel", 29, "OT"),
    (30, "Amos", "Amos", 30, "OT"),
    (31, "Obad", "Obadiah", 31, "OT"),
    (32, "Jonah", "Jonah", 32, "OT"),
    (33, "Mic", "Micah", 33, "OT"),
    (34, "Nah", "Nahum", 34, "OT"),
    (35, "Hab", "Habakkuk", 35, "OT"),
    (36, "Zeph", "Zephaniah", 36, "OT"),
    (37, "Hag", "Haggai", 37, "OT"),
    (38, "Zech", "Zechariah", 38, "OT"),
    (39, "Mal", "Malachi", 39, "OT"),
    (40, "Matt", "Matthew", 40, "NT"),
    (41, "Mark", "Mark", 41, "NT"),
    (42, "Luke", "Luke", 42, "NT"),
    (43, "John", "John", 43, "NT"),
    (44, "Acts", "Acts", 44, "NT"),
    (45, "Rom", "Romans", 45, "NT"),
    (46, "1 Cor", "1 Corinthians", 46, "NT"),
    (47, "2 Cor", "2 Corinthians", 47, "NT"),
    (48, "Gal", "Galatians", 48, "NT"),
    (49, "Eph", "Ephesians", 49, "NT"),
    (50, "Phil", "Philippians", 50, "NT"),
    (51, "Col", "Colossians", 51, "NT"),
    (52, "1 Thess", "1 Thessalonians", 52, "NT"),
    (53, "2 Thess", "2 Thessalonians", 53, "NT"),
    (54, "1 Tim", "1 Timothy", 54, "NT"),
    (55, "2 Tim", "2 Timothy", 55, "NT"),
    (56, "Titus", "Titus", 56, "NT"),
    (57, "Phlm", "Philemon", 57, "NT"),
    (58, "Heb", "Hebrews", 58, "NT"),
    (59, "Jas", "James", 59, "NT"),
    (60, "1 Pet", "1 Peter", 60, "NT"),
    (61, "2 Pet", "2 Peter", 61, "NT"),
    (62, "1 John", "1 John", 62, "NT"),
    (63, "2 John", "2 John", 63, "NT"),
    (64, "3 John", "3 John", 64, "NT"),
    (65, "Jude", "Jude", 65, "NT"),
    (66, "Rev", "Revelation", 66, "NT"),
]

REQUIRED_COLUMNS = ("book", "chapter", "verse", "text")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Build a KJV.sqlite database from a one-row-per-verse CSV file."
    )
    parser.add_argument("input_csv", type=Path, help="CSV with book,chapter,verse,text columns")
    parser.add_argument("output_sqlite", type=Path, help="Destination SQLite database path")
    return parser.parse_args()


def normalize_key(value):
    return " ".join(value.strip().lower().replace(".", "").split())


def ensure_schema(connection):
    connection.executescript(
        """
        DROP TABLE IF EXISTS verses;
        DROP TABLE IF EXISTS books;

        CREATE TABLE books (
            id INTEGER PRIMARY KEY,
            abbreviation TEXT NOT NULL,
            name TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            testament TEXT NOT NULL
        );

        CREATE TABLE verses (
            id INTEGER PRIMARY KEY,
            book_id INTEGER NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            reference TEXT NOT NULL,
            text TEXT NOT NULL,
            sort_key INTEGER NOT NULL,
            FOREIGN KEY(book_id) REFERENCES books(id)
        );

        CREATE UNIQUE INDEX idx_verses_book_chapter_verse
        ON verses(book_id, chapter, verse);

        CREATE INDEX idx_verses_sort_key
        ON verses(sort_key);

        CREATE INDEX idx_books_sort_order
        ON books(sort_order);
        """
    )


def load_books(connection):
    connection.executemany(
        "INSERT INTO books (id, abbreviation, name, sort_order, testament) VALUES (?, ?, ?, ?, ?)",
        BOOKS,
    )


def build_book_lookup():
    lookup = {}
    for book_id, abbreviation, name, sort_order, _ in BOOKS:
        aliases = {
            name,
            abbreviation,
            name.replace(" ", ""),
            abbreviation.replace(" ", ""),
        }

        if name == "Psalms":
            aliases.update({"Psalm", "Psalm"})
        if name == "Song of Solomon":
            aliases.update({"Song of Songs", "Song", "SOS"})

        if name.startswith(("1 ", "2 ", "3 ")):
            number, remainder = name.split(" ", 1)
            number_aliases = {
                "1": {"1", "First", "I"},
                "2": {"2", "Second", "II"},
                "3": {"3", "Third", "III"},
            }[number]
            for prefix in number_aliases:
                aliases.add(f"{prefix} {remainder}")
                aliases.add(f"{prefix}{remainder.replace(' ', '')}")

        for key in aliases:
            lookup[key] = (book_id, name, sort_order)

    return {normalize_key(key): value for key, value in lookup.items()}


def clean_row(row, line_number):
    normalized = {key.strip().lower(): (value.strip() if value is not None else "") for key, value in row.items()}
    missing = [column for column in REQUIRED_COLUMNS if column not in normalized]
    if missing:
        raise ValueError(f"Missing required CSV columns at line {line_number}: {', '.join(missing)}")

    if not normalized["book"]:
        raise ValueError(f"Empty book value at line {line_number}")
    if not normalized["text"]:
        raise ValueError(f"Empty verse text at line {line_number}")

    try:
        chapter = int(normalized["chapter"])
        verse = int(normalized["verse"])
    except ValueError as error:
        raise ValueError(f"Invalid chapter/verse at line {line_number}: {error}") from error

    if chapter <= 0 or verse <= 0:
        raise ValueError(f"Chapter and verse must be positive integers at line {line_number}")

    return normalized["book"], chapter, verse, normalized["text"]


def verse_rows(reader):
    book_lookup = build_book_lookup()
    next_id = 1

    for line_number, row in enumerate(reader, start=2):
        book_value, chapter, verse, text = clean_row(row, line_number)
        book_key = normalize_key(book_value)
        if book_key not in book_lookup:
            raise ValueError(f"Unknown book name in source data at line {line_number}: {book_value}")

        book_id, canonical_name, sort_order = book_lookup[book_key]
        reference = f"{canonical_name} {chapter}:{verse}"
        sort_key = sort_order * 1_000_000 + chapter * 1_000 + verse

        yield (
            next_id,
            book_id,
            chapter,
            verse,
            reference,
            text,
            sort_key,
        )
        next_id += 1


def main():
    args = parse_args()
    args.output_sqlite.parent.mkdir(parents=True, exist_ok=True)

    with sqlite3.connect(args.output_sqlite) as connection:
        ensure_schema(connection)
        load_books(connection)

        with args.input_csv.open(newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            fieldnames = [field.strip().lower() for field in (reader.fieldnames or [])]
            if not set(REQUIRED_COLUMNS).issubset(fieldnames):
                missing = ", ".join(sorted(set(REQUIRED_COLUMNS) - set(fieldnames)))
                raise ValueError(f"Missing required CSV columns: {missing}")

            connection.executemany(
                """
                INSERT INTO verses (id, book_id, chapter, verse, reference, text, sort_key)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                verse_rows(reader),
            )

        connection.commit()

        verse_count = connection.execute("SELECT COUNT(*) FROM verses").fetchone()[0]
        book_count = connection.execute("SELECT COUNT(*) FROM books").fetchone()[0]

    print(f"Generated {args.output_sqlite}")
    print(f"Books: {book_count}")
    print(f"Verses: {verse_count}")


if __name__ == "__main__":
    main()
