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


def parse_args():
    parser = argparse.ArgumentParser(
        description="Build a KJV.sqlite database from a one-row-per-verse CSV file."
    )
    parser.add_argument("input_csv", type=Path, help="CSV with book,chapter,verse,text columns")
    parser.add_argument("output_sqlite", type=Path, help="Destination SQLite database path")
    return parser.parse_args()


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
        for key in {name.lower(), abbreviation.lower()}:
            lookup[key] = (book_id, name, sort_order)
    lookup["psalm"] = lookup["psalms"]
    lookup["song of songs"] = lookup["song of solomon"]
    return lookup


def verse_rows(reader):
    book_lookup = build_book_lookup()
    next_id = 1

    for row in reader:
        book_key = row["book"].strip().lower()
        if book_key not in book_lookup:
            raise ValueError(f"Unknown book name in source data: {row['book']}")

        book_id, canonical_name, sort_order = book_lookup[book_key]
        chapter = int(row["chapter"])
        verse = int(row["verse"])
        reference = f"{canonical_name} {chapter}:{verse}"
        sort_key = sort_order * 1_000_000 + chapter * 1_000 + verse

        yield (
            next_id,
            book_id,
            chapter,
            verse,
            reference,
            row["text"].strip(),
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
            required_columns = {"book", "chapter", "verse", "text"}
            if not required_columns.issubset(reader.fieldnames or []):
                missing = ", ".join(sorted(required_columns - set(reader.fieldnames or [])))
                raise ValueError(f"Missing required CSV columns: {missing}")

            connection.executemany(
                """
                INSERT INTO verses (id, book_id, chapter, verse, reference, text, sort_key)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                verse_rows(reader),
            )

        connection.commit()


if __name__ == "__main__":
    main()
