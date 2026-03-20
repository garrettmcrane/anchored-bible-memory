# Anchored – Bible Memory — Product Specification

## 1. Overview
App Name: Anchored – Bible Memory

Purpose: Create a comprehensive iPhone application that helps Christians memorize Scripture efficiently through structured tracking, review systems, and intuitive design.

This document serves as the central specification and evolving record for the project including:
- Vision
- Product requirements
- Feature specifications
- Design philosophy
- Technical architecture
- Licensing
- Development history
- Roadmap
- Decisions log

This document will be continuously edited and expanded.

---

## 2. Vision
This app exists to help Christians store God’s Word in their hearts by making Scripture memorization simple, accessible, and deeply integrated into the life of the local church. It provides an intuitive system for individuals and groups to memorize passages together using proven memory methods while tracking progress and encouraging consistency. Small groups, ministries, and churches can assign passages, practice them collectively, and hold one another accountable in the pursuit of knowing Scripture. The goal is not merely reading verses on a screen, but helping believers internalize God’s Word so it shapes their thinking, obedience, and fellowship.

---

## 3. Problem Statement
Existing Bible memory apps fail to meet the needs of serious Scripture memorization for several key reasons:

1. **Poor design quality** – Many current apps look outdated, clunky, and unprofessional. They ignore modern iOS design standards and feel like hobby projects rather than polished software.

2. **Slow verse entry workflows** – Most apps only allow verses to be added one at a time. This makes importing large verse collections extremely tedious and discourages users who already have extensive memorization lists.

3. **Translation limitations** – Many apps restrict or lock Bible translations behind paywalls or licensing limitations, preventing users from memorizing Scripture in their preferred translation.

4. **Rigid memorization systems** – Existing apps typically offer only one or two memorization modes rather than accommodating different learning styles.

5. **Lack of customization** – Users cannot customize memorization accuracy thresholds, review difficulty, or learning methods.

6. **No church or group infrastructure** – Most Bible memory apps are designed for individuals and do not support church groups, ministry teams, or small-group accountability structures.

7. **Weak long‑term memory systems** – Many apps lack true spaced repetition, mastery decay tracking, and long‑term retention systems necessary for lifelong memorization.

8. **Limited progress tracking** – Users often cannot clearly track how many verses they have memorized, how strong their recall is, or their long‑term progress.

9. **Poor passage management** – Many apps struggle to manage multi‑verse passages, full chapters, or thematic collections of Scripture.

10. **Uninspiring Scripture presentation** – Scripture is often presented like generic flashcards rather than through a clean, elegant, and distraction‑free reading experience that reflects the importance of the text.

---

## 4. Target Users
Primary users:
- Christians serious about memorizing Scripture
- Pastors
- Students
- Church members in Bible memory programs

Secondary users:
- Families
- Small groups
- Churches

---

## 5. Core Principles

### 5.1 Simplicity
The app must be simple to use.

### 5.2 Speed
Adding or reviewing verses must take seconds.

### 5.3 Long‑term retention
The system should optimize for lifetime retention.

### 5.4 Clean design
Minimalist modern interface.

---

## 6. Core Features

### 6.1 Verse Entry
Users can add:
- Single verses
- Multi‑verse passages
- Entire chapters

Methods:
- Manual typing
- Paste text
- Select from Bible text

---

### 6.2 Organization
Passages should be organized using a simple, folder-based system.

### Folder System
- Users can create custom folders
- Folders are user-defined (no enforced structure)
- Each verse or passage belongs to one folder

### Design Principles
- Keep organization simple and intuitive
- Avoid complexity (no tagging system in MVP)
- Optimize for clarity over flexibility

### Common Folder Use Cases
- Topics (e.g., Anxiety, Trust, Self-Control)
- Books of the Bible (e.g., Romans, Psalms)
- Life categories (e.g., Work, Family, Spiritual Growth)
- Custom collections (e.g., Favorites, Current Focus)

The goal is to support organization without overwhelming the user with options.

### Search, Filter, and Sort
The library must remain easy to navigate even when users have large verse collections.

Users should be able to:
- Search by reference (e.g., John 3:16)
- Search by verse text or keywords
- Filter by folder
- Filter by mastery status (learning, reviewing, mastered)
- Filter by group vs personal verses
- Sort alphabetically
- Sort by most recent
- Sort by most reviewed / least reviewed
- Sort by due for review

The goal is to make any verse easy to find in seconds, even in very large libraries.

---

### 6.3 Review System
Spaced repetition style review system.

Features:
- Daily review queue
- Difficulty tracking
- Mastery scoring

---

### 6.4 Progress Tracking
Metrics such as:
- Verses memorized
- Passages mastered
- Review streaks

---

### 6.5 Testing Mode
Users attempt to recite passages and verify accuracy.

---

## 7. Design Philosophy

- Clean
- Modern
- Minimal friction

---

## 8. Verse Display & Typography
The presentation of Scripture must be elegant, readable, and distinct from standard UI text while remaining highly customizable.

### Default Design
- **Scripture Font**: Bible-style serif font for verse text to set it apart
- **UI Font**: Clean, modern sans-serif for all non-Scripture UI
- **Layout**: Paragraph format by default
- **Reference Placement**: Top-left, positioned just above the verse text
- **Theme**: System-based (auto light/dark mode following device settings)

### User Customization
Users can adjust display preferences in settings:
- Toggle between multiple Scripture fonts
- Switch between paragraph and line-by-line layouts
- Move or hide verse reference (top/bottom/hidden)
- Force Light Mode or Dark Mode (override system)

### Design Principles
- Scripture should feel visually “set apart” from the rest of the UI
- High readability across lighting conditions
- Minimal distraction during memorization

## 8. Technical Considerations

Platform:
- iOS first

Potential frameworks:
- SwiftUI

---

## 9. Monetization
The app will use a freemium + subscription model designed for growth through groups while maintaining sustainable revenue.

### Free Tier (Permanent)
Users can:
- Join groups
- Memorize assigned group verses
- Add a limited number of personal verses (e.g., up to 5)
- Use a limited set of memorization modes (e.g., 1–2 methods)
- View basic progress metrics

### Premium Subscription
Pricing (target):
- $3.99/month
- $29/year

Premium unlocks:
- Unlimited personal verses
- All memorization methods
- Advanced analytics and visualizations
- Full retention/reminder system
- Ability to create and manage groups

### Free Trial
- 30-day free trial of Premium
- Full access to all features during trial

### Group Growth Model
- Group members can participate for free
- Group leaders must be Premium to create/manage groups

### Design Principles
- Minimize friction for new users
- Encourage group-based adoption
- Provide meaningful free value while maintaining clear upgrade incentives

---

## 10. Licensing

Bible translation licensing will be required depending on translation.

---

## 11. MVP (Version 1.0 Requirements)
The first release of the app should focus on delivering a polished and highly usable core experience rather than a large number of incomplete features.

Version 1.0 must include the following core capabilities:

1. **Beautiful and modern design**  
The app must look and feel professional, clean, and visually appealing. It should follow modern iOS design patterns and SwiftUI standards so that the interface feels native, intuitive, and fast.

2. **Group memorization system**  
Users must be able to create private groups (such as small groups, ministries, or church cohorts). A group leader can assign passages for everyone in the group to memorize, and members can join easily through an invite link, code, or QR code. Assigned verses automatically appear in each member's app and progress can be tracked.

3. **Multiple memorization methods**  
The app should support several different memorization techniques so users can choose what works best for them. Examples include flashcards, typing the verse, first-letter prompts, spoken recitation, and other interactive memory techniques.

4. **Extremely easy verse input**  
Adding verses must be fast and frictionless. Users should be able to add passages through modern input methods such as bulk verse entry, pasted lists of references, or spoken references that are automatically parsed and imported.

These capabilities represent the minimum viable product required before additional features are expanded.

---

## 12. Memorization Methods (MVP)
The first version of the app should support multiple memorization techniques to accommodate different learning styles. The following five methods are considered essential for Version 1.0:

1. **Reference Flashcards**  
Users see the verse reference (e.g., John 3:16) on the front of a digital flashcard. They attempt to recite the verse from memory before flipping the card to reveal the full passage.

2. **First-Letter Typing**  
The verse is represented by the first letter of each word. Users type the sequence of letters to reinforce word order and structure.

3. **Listening Mode**  
The verse is read aloud by the app so the user can listen and repeat it. This supports auditory memorization and review during activities such as commuting or walking.

4. **Voice Recitation**  
Users speak the verse aloud and speech recognition evaluates how accurately the verse was recited.

5. **Progressive Word Hiding**  
The verse begins fully visible and progressively hides more words as the user advances, forcing deeper recall over time.

These methods form the core memorization engine for the MVP. Additional memorization techniques may be introduced in later versions.

## 13. Home Screen (Dashboard)
The home screen serves as the central “mission control” and should immediately guide daily action.

### Core Elements
- **Personal Greeting** (time-based) with user name
- **Verse of the Day** (small, minimal; add-to-memory action)
- **Primary CTA: Review Now** (prominent button showing verses due)
- **Progress Summary** (cards):
  - Verses Mastered
  - In Progress
  - Remaining toward current set (e.g., 35/41)
- **Streak / Consistency** (simple indicator)

### Group Integration (if user is in a group)
- Current group name
- Group progress summary (e.g., team completion %, your standing)
- Next assigned verses / due items

### Design Direction
- Clean, modern, iOS-native (SwiftUI)
- Visually rich but readable (glassy cards, smooth animations)
- Fast load, zero friction to start review

## 14. App Navigation (Tabs)
The app uses a bottom tab bar with a maximum of five primary tabs for clarity and speed.

### Tabs
1. **Home**  
   Dashboard / mission control with greeting, verse of the day, review prompt, progress summary, and (if applicable) group snapshot.

2. **Library**  
   Central hub for all personal verses and passages.
   - Organized into folders/collections (e.g., Anxiety, Trust, Discipline)
   - Color-coded categories
   - Powerful filtering and quick-review entry

3. **Add**  
   Primary creation flow (core feature).
   - Add via typing, paste, Bible selection, voice, or image
   - Assign to folders/collections
   - Fast, minimal-friction UX

4. **Groups**  
   Group-based memorization.
   - List of joined groups
   - Group verse libraries
   - Assigned verses and progress within each group

5. **Progress**  
   Analytics and insights.
   - Charts, trends, streaks, retention
   - “Verses Mastered” as the anchor metric

### Profile Access
- Profile is accessed via an avatar icon on the Home screen (top corner)
- Includes account, settings, preferences

## 15. Verse Add Flow (MVP)
The Add experience must feel effortless while handling complex inputs intelligently.

### Entry
- User taps the central **Add (+)** button
- Presented with three primary options only:
  1. **Paste / Type**
  2. **Search Bible**
  3. **Import** (advanced)

### Paste / Type (Primary Path)
- User pastes or types text (can be messy)
- App automatically:
  - Extracts verse references from text
  - Cleans non-relevant content
  - Resolves references to full Scripture text (based on selected translation)
- Shows a clean preview of detected passages

### Search Bible
- Select Book → Chapter → Verse(s)
- Supports multi-select and ranges (e.g., 3–5)
- Toggle:
  - Combine into one passage
  - Keep as separate verses

### Import (Advanced)
- Voice input (spoken references parsed automatically)
- CSV upload (bulk import)
- (Future) image/screenshot recognition

### Post-Add (Quick Setup)
Minimal required inputs:
- Folder / category (optional default)
- Group assignment (optional)
- Combine vs separate (if applicable)

### Output
- Verses are created and added to the user’s library in seconds
- Default review settings applied

### Design Principles
- Extreme simplicity on the surface
- Powerful parsing and automation behind the scenes
- Goal: Paste → Preview → Save in under 5 seconds

## 16. Review Flow (MVP)
The review experience is fast, flexible, and data-driven.

### Entry Options
When the user taps **Review**, they choose one of three modes:

1. **Review All**
- Runs through all verses marked as memorized
- Used for full refresh / confidence check

2. **Smart Review**
- Automatically selects verses with weakest performance
- Based on error rate, recent failures, and decay signals
- Optimized for quick, high-impact review sessions

3. **Custom Selection**
- User manually selects verses to review
- Can filter by folder, tag, or group

### Method Selection
After selecting verses, the user chooses a memorization method:
- Flashcards
- First-letter typing
- Voice recitation
- Listening mode
- Progressive word hiding

(Only methods available to the user’s tier are shown.)

### Review Session
- Verses are presented sequentially
- User completes each verse using the selected method
- Accuracy is evaluated per verse
- Feedback is immediate and clear

### Completion
- Immediate simple summary (forced display): key stats (accuracy, verses completed, time)
- Optional detailed breakdown (tap to view): per-verse performance, mistakes, accuracy history
- Updates mastery/retention scores
- Prompts next action (continue, switch method, or finish)

### Error Handling & Retries
- If a user answers incorrectly:
  1. Highlight mistakes clearly
  2. Show the correct verse
  3. Allow a retry (if available)

- Retry system:
  - Free users: 1 retry per day (non-stacking)
  - Premium users: 2 retries per day (non-stacking)

- If retry is used and still incorrect (or no retries remain):
  - Verse is sent to the top of the review queue
  - Mastery confidence is reduced
  - Marked as high-priority for future review

### Streak Policy
- No streak system
- No streak rewards or penalties

Rationale:
- Avoid legalism and pressure-based engagement
- Encourage sincere, thoughtful memorization
- Support flexible review cadence based on user needs

## 16. Group Feature (MVP)
The group system is a core differentiator of the app and must be simple, clear, and effective.

### Group Leader Capabilities
A group leader should be able to:

- View a list of all members in the group
- See each member’s progress toward assigned verses
- Track how many assigned verses each member has memorized

### Group Joining System
Joining a group must be extremely simple, fast, and accessible for users of all ages and technical ability levels.

The app should support multiple join methods:

- Invite links (tap to join)
- Invite codes (manual entry)
- QR codes (scan to join instantly)
- Email invites (optional)

The goal is to eliminate friction entirely so that a user can join a group in seconds with minimal instruction.

Progress visibility should be simple and easy to understand at a glance, while also offering deeper insights through rich visual analytics.

### Verse Assignment System (Individual + Group)
Verse assignment must be extremely fast, intuitive, and flexible. The same system should be used for both individual users and group leaders.

Supported input methods:

- Manual typing of verses or references
- Selecting verses directly from Bible text
- Pasting lists of verse references
- Choosing from pre-built verse lists or plans
- Voice input (user speaks references and they are parsed automatically)
- Image/screenshot recognition (AI extracts verse references from images)

The system should intelligently parse and organize all inputs into structured passages with minimal user effort.

The goal is to make adding verses dramatically faster and easier than any existing Bible memory app.

### Assignment Types
Group leaders can assign verses in two ways:

- **Required** — all group members are expected to memorize these verses
- **Optional** — suggested verses for additional study

Leaders can choose the assignment type per verse or per list.

This allows flexibility while maintaining accountability where needed.

### Progress Visibility Settings
Progress visibility within a group is configurable by the group leader:

- Everyone can see everyone’s progress
- Only the leader can see all members’ progress
- Members can choose to make their own progress public or private (if enabled by leader)

The goal is to balance accountability with privacy based on group preference.

### Notifications & Communication (MVP)
Notifications should be minimal and focused strictly on supporting memorization, not replacing existing messaging platforms.

- Notifications are optional
- Group leaders can enable or disable group-related reminders
- Individual users can control personal reminder settings

Supported notification types (limited scope):
- Personal practice reminders
- Upcoming or overdue assigned verses

Non-goals:
- No in-app messaging threads
- No group chat or social feed features

The app is not intended to function as a communication platform, but as a focused tool for Scripture memorization.

### Authentication & Accounts (MVP)
The app requires user accounts to ensure data persistence, cloud syncing, and cross-device access.

Supported sign-in methods:
- Email and password (primary method; app-managed database)
- Sign in with Apple
- Sign in with Google

Requirements:
- Account creation is required (no local-only mode)
- All user data is stored securely and synced across devices
- Users can access their data from multiple devices (iPhone, iPad, etc.)

Rationale:
- Prevent data loss
- Enable seamless device switching
- Support group features and progress tracking

### Progress Tracking System (Vision)
Progress should not be limited to basic percentages. The app should include highly visual, modern, and insightful analytics that make tracking Scripture memorization engaging and motivating.

Key characteristics:

- Beautiful, modern charts and graphs (clean, iOS-native design)
- Multiple progress dimensions (not just completion percentage)
- Historical tracking over time
- Insightful metrics that reveal patterns and consistency

Examples of metrics and visuals:

- Verses memorized over time (line graph)
- Consistency / streak tracking
- Mastery levels (learning vs reviewing vs mastered)
- Retention strength and decay over time
- Group comparison views (optional, based on privacy settings)

### Core Progress Metric
The primary metric that defines user progress is:

**Verses Mastered**

This represents the number of verses a user has fully memorized according to defined accuracy and mastery thresholds.

### Mastery Definition System
Mastery is not fixed. It is configurable based on user preference and group standards.

- Individual users can define their own mastery criteria
- Group leaders can define a standardized mastery requirement for all group members

Possible mastery criteria include:
- Accuracy threshold (e.g., 90%, 95%, 100%)
- Number of successful repetitions
- Consistency over multiple sessions or days
- Method-specific validation (typing, speaking, etc.)

When a user is part of a group, the group’s mastery definition overrides individual settings for assigned verses.

### Retention & Review System (Post-Mastery)
Once a verse is marked as mastered, it should not be considered complete indefinitely.

The app must include a system to maintain long-term retention:

- Users can set reminders to review mastered verses
- The system should encourage periodic review to prevent memory decay

### Review Interval System
Users control how often they review verses, with two simple modes:

1. **Manual Mode**
- User selects a fixed interval (e.g., every 3, 5, 7, or 14 days)
- Interval remains static unless changed by the user

2. **Automatic Mode**
- App dynamically adjusts review intervals based on performance
- Starts with a short interval (e.g., 3 days)
- Increases interval when recall is strong
- Decreases interval when errors occur
- Learns user retention patterns over time

Design Principle:
- Keep the system simple and understandable
- Give users control while offering intelligent automation

The goal is to balance user preference with effective long-term memory retention.
