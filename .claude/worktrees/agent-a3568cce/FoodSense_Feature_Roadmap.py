#!/usr/bin/env python3
"""Generate the FoodSense Feature Roadmap PDF."""

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.lib.colors import HexColor, white, black
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas
from reportlab.lib import colors
import os

OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "FoodSense_Feature_Roadmap.pdf")

# Brand colors
GREEN = HexColor("#16A34A")
DARK_GREEN = HexColor("#15803D")
BLUE = HexColor("#2563EB")
AMBER = HexColor("#D97706")
RED = HexColor("#DC2626")
PURPLE = HexColor("#7C3AED")
DARK = HexColor("#111827")
GRAY = HexColor("#6B7280")
LIGHT_GRAY = HexColor("#F3F4F6")
LIGHT_GREEN = HexColor("#DCFCE7")
LIGHT_BLUE = HexColor("#DBEAFE")
LIGHT_AMBER = HexColor("#FEF3C7")
LIGHT_PURPLE = HexColor("#EDE9FE")
LIGHT_RED = HexColor("#FEE2E2")

styles = getSampleStyleSheet()

# Custom styles
styles.add(ParagraphStyle(
    name='DocTitle', fontSize=28, leading=34, textColor=DARK,
    fontName='Helvetica-Bold', alignment=TA_CENTER, spaceAfter=6
))
styles.add(ParagraphStyle(
    name='DocSubtitle', fontSize=14, leading=18, textColor=GRAY,
    fontName='Helvetica', alignment=TA_CENTER, spaceAfter=30
))
styles.add(ParagraphStyle(
    name='SectionTitle', fontSize=20, leading=26, textColor=DARK,
    fontName='Helvetica-Bold', spaceBefore=24, spaceAfter=12
))
styles.add(ParagraphStyle(
    name='SubSection', fontSize=14, leading=18, textColor=DARK_GREEN,
    fontName='Helvetica-Bold', spaceBefore=16, spaceAfter=8
))
styles.add(ParagraphStyle(
    name='FeatureTitle', fontSize=11, leading=15, textColor=DARK,
    fontName='Helvetica-Bold', spaceBefore=4, spaceAfter=2
))
styles.add(ParagraphStyle(
    name='FeatureDesc', fontSize=10, leading=14, textColor=GRAY,
    fontName='Helvetica', spaceBefore=0, spaceAfter=6, alignment=TA_JUSTIFY
))
styles.add(ParagraphStyle(
    name='BodyText2', fontSize=10, leading=14, textColor=DARK,
    fontName='Helvetica', spaceBefore=2, spaceAfter=4, alignment=TA_JUSTIFY
))
styles.add(ParagraphStyle(
    name='PhaseHeader', fontSize=16, leading=20, textColor=white,
    fontName='Helvetica-Bold', spaceBefore=0, spaceAfter=0, alignment=TA_CENTER
))
styles.add(ParagraphStyle(
    name='TableHeader', fontSize=9, leading=12, textColor=white,
    fontName='Helvetica-Bold', alignment=TA_CENTER
))
styles.add(ParagraphStyle(
    name='TableCell', fontSize=9, leading=12, textColor=DARK,
    fontName='Helvetica', alignment=TA_LEFT
))
styles.add(ParagraphStyle(
    name='TableCellCenter', fontSize=9, leading=12, textColor=DARK,
    fontName='Helvetica', alignment=TA_CENTER
))
styles.add(ParagraphStyle(
    name='FooterText', fontSize=8, leading=10, textColor=GRAY,
    fontName='Helvetica', alignment=TA_CENTER
))
styles.add(ParagraphStyle(
    name='TOCItem', fontSize=11, leading=16, textColor=DARK,
    fontName='Helvetica', spaceBefore=2, spaceAfter=2
))
styles.add(ParagraphStyle(
    name='TOCSection', fontSize=12, leading=18, textColor=DARK_GREEN,
    fontName='Helvetica-Bold', spaceBefore=8, spaceAfter=2
))


def add_page_number(canvas_obj, doc):
    """Add page number and footer to each page."""
    canvas_obj.saveState()
    canvas_obj.setFont('Helvetica', 8)
    canvas_obj.setFillColor(GRAY)
    canvas_obj.drawCentredString(A4[0] / 2, 20 * mm, f"FoodSense Feature Roadmap  |  Page {doc.page}")
    # Top accent line
    canvas_obj.setStrokeColor(GREEN)
    canvas_obj.setLineWidth(3)
    canvas_obj.line(0, A4[1] - 10, A4[0], A4[1] - 10)
    canvas_obj.restoreState()


def colored_box(text, color, text_color=white):
    """Create a colored box with text."""
    return Table(
        [[Paragraph(text, styles['PhaseHeader'])]],
        colWidths=[460],
        rowHeights=[36],
        style=TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), color),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('ROUNDEDCORNERS', [8, 8, 8, 8]),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
        ])
    )


def section_divider():
    return HRFlowable(width="100%", thickness=1, color=HexColor("#E5E7EB"), spaceBefore=12, spaceAfter=12)


def feature_block(number, title, description, complexity="Medium", server=False):
    """Create a formatted feature entry."""
    elements = []
    server_tag = '  <font color="#7C3AED">[Server]</font>' if server else ''
    complexity_colors = {"Low": "#16A34A", "Medium": "#D97706", "High": "#DC2626"}
    c_color = complexity_colors.get(complexity, "#6B7280")
    elements.append(Paragraph(
        f'<font color="#16A34A">{number}.</font> {title}{server_tag}'
        f'  <font size="8" color="{c_color}">({complexity})</font>',
        styles['FeatureTitle']
    ))
    elements.append(Paragraph(description, styles['FeatureDesc']))
    return elements


def build_pdf():
    doc = SimpleDocTemplate(
        OUTPUT_PATH, pagesize=A4,
        leftMargin=30 * mm, rightMargin=30 * mm,
        topMargin=25 * mm, bottomMargin=25 * mm
    )
    story = []

    # ========== COVER PAGE ==========
    story.append(Spacer(1, 80))
    story.append(Paragraph("FoodSense", styles['DocTitle']))
    story.append(Paragraph("Complete Feature Roadmap", ParagraphStyle(
        'CoverSub', parent=styles['DocSubtitle'], fontSize=18, textColor=GREEN
    )))
    story.append(Spacer(1, 20))
    story.append(HRFlowable(width="40%", thickness=2, color=GREEN, spaceBefore=0, spaceAfter=20))
    story.append(Paragraph(
        "iOS (Swift/SwiftUI) + Android (Kotlin/Jetpack Compose)<br/>"
        "Server Backend (Node.js/Python + Firebase + Cloud AI)",
        styles['DocSubtitle']
    ))
    story.append(Spacer(1, 40))

    # Stats box
    stats_data = [
        [Paragraph('<font color="#FFFFFF"><b>Implemented</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Social & Gamification</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>AI Features</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Total</b></font>', styles['TableHeader'])],
        [Paragraph('<font size="16"><b>30+</b></font>', styles['TableCellCenter']),
         Paragraph('<font size="16"><b>72</b></font>', styles['TableCellCenter']),
         Paragraph('<font size="16"><b>50</b></font>', styles['TableCellCenter']),
         Paragraph('<font size="16"><b>150+</b></font>', styles['TableCellCenter'])],
    ]
    stats_table = Table(stats_data, colWidths=[105, 105, 105, 105])
    stats_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), GREEN),
        ('BACKGROUND', (0, 1), (-1, 1), LIGHT_GREEN),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('ROUNDEDCORNERS', [6, 6, 6, 6]),
        ('TOPPADDING', (0, 1), (-1, 1), 10),
        ('BOTTOMPADDING', (0, 1), (-1, 1), 10),
    ]))
    story.append(stats_table)
    story.append(Spacer(1, 40))
    story.append(Paragraph("April 2026", ParagraphStyle(
        'Date', parent=styles['DocSubtitle'], fontSize=12
    )))
    story.append(PageBreak())

    # ========== TABLE OF CONTENTS ==========
    story.append(Paragraph("Table of Contents", styles['SectionTitle']))
    story.append(section_divider())
    toc_items = [
        ("Part 1", "Implemented Features (30+)", "3"),
        ("Part 2", "Social & Friends Features (25)", "6"),
        ("Part 3", "Badges & Awards System (50)", "8"),
        ("Part 4", "AI Features (50)", "11"),
        ("Part 5", "Server Architecture", "16"),
        ("Part 6", "Implementation Priority", "17"),
        ("Part 7", "Tech Stack Summary", "18"),
    ]
    for part, title, page in toc_items:
        story.append(Paragraph(
            f'<font color="#16A34A"><b>{part}</b></font>  '
            f'{title} <font color="#9CA3AF">{"." * 60}</font> {page}',
            styles['TOCItem']
        ))
    story.append(PageBreak())

    # ========== PART 1: IMPLEMENTED FEATURES ==========
    story.append(colored_box("PART 1: IMPLEMENTED FEATURES", GREEN))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "These features are fully built and running on both iOS and Android. "
        "The app has been tested on a physical iPhone and Android emulator.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    # Phase 1
    story.append(Paragraph("Phase 1: Core Infrastructure", styles['SubSection']))
    for f in feature_block(1, "Backend Proxy (Firebase Cloud Functions)", "3 API endpoints to proxy Gemini requests, hiding the API key server-side. Client-side rate limiting (1 req/sec, 100/day) and server-side (200/day, 500ms)."):
        story.append(f)
    for f in feature_block(2, "API Key Security", "Hardcoded API key removed from source code. Replaced with BuildConfig/proxy-first architecture. Key only exists in server environment variables."):
        story.append(f)
    for f in feature_block(3, "Network Monitor", "Real-time connectivity detection using NWPathMonitor (iOS) and ConnectivityManager (Android). Shows offline banner and disables cloud features when disconnected."):
        story.append(f)
    for f in feature_block(4, "Crash Reporting & Analytics", "Firebase Crashlytics for crash reports + Firebase Analytics tracking 7 events: food_logged, coach_asked, scan_completed, barcode_scanned, water_logged, manual_log, streak_updated."):
        story.append(f)
    for f in feature_block(5, "Settings Screen", "Theme switching (light/dark/system), legal info pages, data export to JSON, delete all data, app version display."):
        story.append(f)

    # Phase 2
    story.append(Paragraph("Phase 2: User Experience", styles['SubSection']))
    for f in feature_block(6, "Onboarding Flow", "4-page paged walkthrough with swipe navigation: Welcome, Camera Demo, Nutrition Tracking, Profile Setup with weight/height/age/gender/activity/goal inputs."):
        story.append(f)
    for f in feature_block(7, "Firebase Authentication", "Email/password sign-in + anonymous 'Continue as Guest' mode. Auth gate flow: Onboarding then Login then Main app. Graceful fallback when Firebase is not configured."):
        story.append(f)
    for f in feature_block(8, "Theme Support", "Light/dark/system theme with custom high-contrast color schemes. Guaranteed readable contrast in both modes."):
        story.append(f)
    for f in feature_block(9, "iPad Layout Fix", "Added .navigationViewStyle(.stack) on all NavigationViews to prevent split-view rendering issues on iPad."):
        story.append(f)

    # Phase 3
    story.append(Paragraph("Phase 3: Nutrition & Health", styles['SubSection']))
    for f in feature_block(10, "Barcode Scanner", "Vision framework (iOS) / ML Kit (Android) scanning EAN-13, EAN-8, UPC-E barcodes. Looks up nutrition via Open Food Facts API."):
        story.append(f)
    for f in feature_block(11, "Manual Food Logging", "Search 1000+ Indian foods from INDB database + remote AI-powered search. Portion size adjustment with real-time calorie recalculation."):
        story.append(f)
    for f in feature_block(12, "Local Food Detection (TFLite)", "YOLOv8 model bundled offline (237MB). 72 iOS / 95 Android food classes. 640x640 input with on-device inference."):
        story.append(f)
    for f in feature_block(13, "Cloud Food Analysis (Gemini)", "Camera photo sent to Gemini Flash API for AI food identification with full nutrition breakdown including macros and micronutrients."):
        story.append(f)

    story.append(PageBreak())

    for f in feature_block(14, "Multi-item Detection", "Detect and log multiple food items from a single photo. Each item gets individual nutrition info."):
        story.append(f)
    for f in feature_block(15, "Health Integration", "HealthKit (iOS) / Health Connect (Android) for reading steps, sleep hours, active calories burned, and hydration data."):
        story.append(f)
    for f in feature_block(16, "BLE Smart Scale", "CoreBluetooth / Android BLE pairing with smart scales. Live weight reading integrated into portion sizing for accurate nutrition calculation."):
        story.append(f)

    # Phase 4
    story.append(Paragraph("Phase 4: Engagement & Gamification", styles['SubSection']))
    for f in feature_block(17, "Streaks & Badges", "Consecutive day logging tracker with 3 badge tiers (7-day, 30-day, 100-day). Persisted locally with streak recovery logic."):
        story.append(f)
    for f in feature_block(18, "Local Notifications", "Meal reminders (breakfast 8am, lunch 12:30pm, dinner 7pm) and hydration reminders every 2 hours. Configurable via settings."):
        story.append(f)
    for f in feature_block(19, "AI Health Coach", "4 coaching prompt chips: Healthy Recipe, What to Eat, Health Check, Motivation. Context-aware prompts include user stats and today's food log."):
        story.append(f)
    for f in feature_block(20, "Water Tracking", "Manual +250ml water logging with daily total display and HealthKit/Health Connect sync."):
        story.append(f)

    # Phase 5
    story.append(Paragraph("Phase 5: Data & Persistence", styles['SubSection']))
    for f in feature_block(21, "Database Migration", "UserDefaults to CoreData (iOS) / SharedPreferences to Room (Android). One-time automatic migration preserving all user data."):
        story.append(f)
    for f in feature_block(22, "Firestore Sync (Scaffold)", "SyncManager scaffolded for future cloud sync of food logs and user stats across devices."):
        story.append(f)
    for f in feature_block(23, "Home Screen Widget", "WidgetKit (iOS) / Glance AppWidget (Android) showing today's calorie count and remaining budget. Updates on every food log."):
        story.append(f)

    # Phase 6
    story.append(Paragraph("Phase 6: Launch Readiness", styles['SubSection']))
    for f in feature_block(24, "Localization (English + Hindi)", "71 string keys localized on each platform. Full Hindi translation for all UI text."):
        story.append(f)
    for f in feature_block(25, "Accessibility", "Complete VoiceOver labels/hints (iOS) and contentDescription/semantics (Android) across every screen and interactive element."):
        story.append(f)
    for f in feature_block(26, "Unit Tests (41 cases)", "NutritionManagerTests + APIResponseParsingTests on both platforms covering calorie budget, macro scaling, JSON parsing, error paths."):
        story.append(f)
    for f in feature_block(27, "UI Tests", "OnboardingUITests + FoodLoggingUITests on both platforms for end-to-end flow validation."):
        story.append(f)
    for f in feature_block(28, "CI/CD Pipelines", "GitHub Actions workflows for both iOS and Android with LFS support for the TFLite model."):
        story.append(f)
    for f in feature_block(29, "Play Asset Delivery", "Install-time asset pack module for the 237MB TFLite model to stay under Play Store APK size limits."):
        story.append(f)
    for f in feature_block(30, "Store Metadata", "App Store and Play Store descriptions, keywords, and category information ready for submission."):
        story.append(f)

    story.append(PageBreak())

    # ========== PART 2: SOCIAL & FRIENDS ==========
    story.append(colored_box("PART 2: SOCIAL & FRIENDS FEATURES", BLUE))
    story.append(Spacer(1, 16))

    story.append(Paragraph("Finding & Connecting", styles['SubSection']))
    social_features = [
        (1, "Add Friends via Phone Contacts", "Scan contacts to find existing FoodSense users. Send invite links with referral tracking to non-users.", True),
        (2, "Username & Profile Cards", "Shareable QR code profile card showing avatar, level, streak, top badges. Deep-link to add friend.", True),
        (3, "Friend Activity Feed", "Real-time feed of friends' meals, achievements, and streaks. Like and react to posts.", True),
        (4, "Accountability Partner", "Pair with one friend who gets push notifications if you miss logging for a day. Mutual opt-in.", True),
    ]
    for num, title, desc, server in social_features:
        for f in feature_block(num, title, desc, "High", server):
            story.append(f)

    story.append(Paragraph("Challenges & Competitions", styles['SubSection']))
    challenge_features = [
        (5, "Weekly Step Challenge", "Compete with friends on weekly step count. Live leaderboard with real-time rankings pulled from HealthKit/Health Connect.", True),
        (6, "Calorie Accuracy Challenge", "Both players scan the same food. Closest to verified nutrition wins points. Great for learning portion estimation.", True),
        (7, "Hydration Race", "First to hit 3L water target in a day wins. Daily reset. Push notification when opponent is close.", True),
        (8, "Streak Wars", "Head-to-head streak competition. Longest consecutive logging streak wins weekly prize (badge).", True),
        (9, "Team Challenges", "Form teams of 3-5, compete against other teams on combined goals: total steps, days logged, vegetables eaten.", True),
        (10, "Monthly Nutrition Bingo", "5x5 bingo card with goals like 'Eat 5 fruits', 'Log every meal for 3 days', 'Try a new food'. First to complete a line wins.", True),
        (11, "Cook-Off Challenge", "Friends share photos of home-cooked meals. Vote on healthiest and most creative. Weekly winners earn special badge.", True),
        (12, "Macro Match", "Set a target macro split (40/30/30). Compete on who hits closest to targets each day. Teaches balanced eating.", True),
    ]
    for num, title, desc, server in challenge_features:
        for f in feature_block(num, title, desc, "High", server):
            story.append(f)

    story.append(Paragraph("Sharing & Interaction", styles['SubSection']))
    sharing_features = [
        (13, "Meal Sharing", "Share what you ate with friends. They can copy-log the same meal with one tap, inheriting all nutrition data.", True),
        (14, "Recipe Exchange", "Share custom recipes with full nutrition breakdown. Friends can save to their personal recipe book.", True),
        (15, "Reaction Emojis", "React to friends' meals with contextual emojis: fire, muscle, salad, clap, heart. Reactions visible in feed.", True),
        (16, "Group Meal Plans", "Shared meal plan for households/roommates. Auto-split grocery list. Sync across all members' apps.", True),
        (17, "Photo Food Battles", "Weekly themed photo contest (e.g., 'Best Breakfast'). Community voting. Winners featured on leaderboard.", True),
        (18, "Nutrition Nudges", "Send gentle reminders to friends: 'Hey, don't forget to log lunch!' Configurable do-not-disturb hours.", True),
        (19, "Share Achievement Cards", "Generate beautiful, branded cards showing stats and badges. One-tap share to Instagram Stories, WhatsApp, Twitter.", False),
    ]
    for num, title, desc, server in sharing_features:
        for f in feature_block(num, title, desc, "Medium", server):
            story.append(f)

    story.append(PageBreak())

    story.append(Paragraph("Leaderboards & Leagues", styles['SubSection']))
    league_features = [
        (20, "Global Leaderboard", "Weekly/monthly rankings by streak length, foods logged, healthy eating score. Filterable by category.", True),
        (21, "Friends Leaderboard", "Rank among your friends only. Categories: steps, streaks, consistency, macro accuracy.", True),
        (22, "City/Country Leaderboard", "See how you rank in your city or country. Location-based community building.", True),
        (23, "League System", "Bronze, Silver, Gold, Platinum, Diamond leagues. Weekly promote/relegate based on activity score. Top 20% promote, bottom 20% relegate.", True),
        (24, "Season Rewards", "3-month seasons with exclusive badges and rewards for top performers. Season history preserved in profile.", True),
        (25, "Hall of Fame", "All-time records: longest streak ever, most foods logged, most challenges won. Permanent recognition.", True),
    ]
    for num, title, desc, server in league_features:
        for f in feature_block(num, title, desc, "High", server):
            story.append(f)

    story.append(PageBreak())

    # ========== PART 3: BADGES & AWARDS ==========
    story.append(colored_box("PART 3: BADGES & AWARDS SYSTEM", AMBER))
    story.append(Spacer(1, 16))

    story.append(Paragraph("Streak Badges", styles['SubSection']))
    streak_badges = [
        ("First Flame", "3-day logging streak"),
        ("Week Warrior", "7-day streak"),
        ("Fortnight Fighter", "14-day streak"),
        ("Monthly Master", "30-day streak"),
        ("Century Champion", "100-day streak"),
        ("Year of Commitment", "365-day streak"),
        ("Streak Survivor", "Recover a streak within 24 hours of missing"),
    ]
    badge_data = [[
        Paragraph('<font color="#FFFFFF"><b>Badge Name</b></font>', styles['TableHeader']),
        Paragraph('<font color="#FFFFFF"><b>Requirement</b></font>', styles['TableHeader']),
    ]]
    for name, req in streak_badges:
        badge_data.append([
            Paragraph(f'<b>{name}</b>', styles['TableCell']),
            Paragraph(req, styles['TableCell']),
        ])
    badge_table = Table(badge_data, colWidths=[150, 310])
    badge_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), AMBER),
        ('BACKGROUND', (0, 1), (-1, -1), LIGHT_AMBER),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(badge_table)
    story.append(Spacer(1, 12))

    story.append(Paragraph("Food Logging Milestones", styles['SubSection']))
    log_badges = [
        ("First Bite", "Log your first food"),
        ("Snap Happy", "Log 10 foods via camera scan"),
        ("Century Logger", "Log 100 foods total"),
        ("Thousand Club", "Log 1,000 foods"),
        ("Data Lover", "Log every meal for a full week (21 meals)"),
        ("Rainbow Plate", "Log 5 different colored foods in one day"),
        ("World Palate", "Log foods from 10 different cuisines"),
        ("Home Chef", "Log 20 home-cooked meals"),
        ("Barcode Blitz", "Scan 50 barcodes total"),
    ]
    log_data = [[
        Paragraph('<font color="#FFFFFF"><b>Badge Name</b></font>', styles['TableHeader']),
        Paragraph('<font color="#FFFFFF"><b>Requirement</b></font>', styles['TableHeader']),
    ]]
    for name, req in log_badges:
        log_data.append([
            Paragraph(f'<b>{name}</b>', styles['TableCell']),
            Paragraph(req, styles['TableCell']),
        ])
    log_table = Table(log_data, colWidths=[150, 310])
    log_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), GREEN),
        ('BACKGROUND', (0, 1), (-1, -1), LIGHT_GREEN),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(log_table)
    story.append(Spacer(1, 12))

    story.append(Paragraph("Nutrition Achievement Badges", styles['SubSection']))
    nutrition_badges = [
        ("Bullseye", "Hit exact calorie target (within 50 kcal) for a day"),
        ("Perfect Balance", "Hit all 3 macro targets within 10% in one day"),
        ("Protein King/Queen", "Hit protein goal for 7 consecutive days"),
        ("Veggie Champion", "Log vegetables in every meal for 3 days"),
        ("Omega Hero", "Log fish/omega-3 rich foods 3 times in a week"),
        ("Sugar Crusher", "Stay under 25g added sugar for 5 consecutive days"),
        ("Hydration Hero", "Hit 3L water target for 7 consecutive days"),
        ("Breakfast Boss", "Log breakfast before 9am for 14 days straight"),
        ("Fiber Fanatic", "Eat 30g+ fiber for 5 days in a row"),
        ("Iron Will", "Meet iron RDA for 7 consecutive days"),
    ]
    n_data = [[
        Paragraph('<font color="#FFFFFF"><b>Badge Name</b></font>', styles['TableHeader']),
        Paragraph('<font color="#FFFFFF"><b>Requirement</b></font>', styles['TableHeader']),
    ]]
    for name, req in nutrition_badges:
        n_data.append([
            Paragraph(f'<b>{name}</b>', styles['TableCell']),
            Paragraph(req, styles['TableCell']),
        ])
    n_table = Table(n_data, colWidths=[150, 310])
    n_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), BLUE),
        ('BACKGROUND', (0, 1), (-1, -1), LIGHT_BLUE),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(n_table)

    story.append(PageBreak())

    story.append(Paragraph("Health & Fitness Badges", styles['SubSection']))
    health_badges = [
        ("10K Steps", "Hit 10,000 steps in a day"),
        ("Marathon Walker", "Accumulate 42km of walking in a week"),
        ("Sleep Scholar", "Get 7-8 hours of sleep for 7 consecutive nights"),
        ("Calorie Deficit Pro", "Maintain a healthy deficit for 14 days"),
        ("Gaining Ground", "Maintain a healthy surplus for 14 days"),
        ("Active Lifestyle", "Burn 500+ active calories for 5 days straight"),
    ]
    h_data = [[
        Paragraph('<font color="#FFFFFF"><b>Badge Name</b></font>', styles['TableHeader']),
        Paragraph('<font color="#FFFFFF"><b>Requirement</b></font>', styles['TableHeader']),
    ]]
    for name, req in health_badges:
        h_data.append([Paragraph(f'<b>{name}</b>', styles['TableCell']), Paragraph(req, styles['TableCell'])])
    h_table = Table(h_data, colWidths=[150, 310])
    h_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PURPLE),
        ('BACKGROUND', (0, 1), (-1, -1), LIGHT_PURPLE),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6), ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(h_table)
    story.append(Spacer(1, 12))

    story.append(Paragraph("Social Badges", styles['SubSection']))
    social_badges = [
        ("Social Butterfly", "Add 5 friends"),
        ("Accountability Ace", "Complete a challenge with a friend"),
        ("Challenge Champion", "Win 3 challenges"),
        ("Recruiter", "Invite 3 friends who join the app"),
        ("Supporter", "React to 50 friends' meals"),
        ("Recipe Sharer", "Share 10 recipes with friends"),
        ("League Legend", "Reach Diamond league"),
        ("Team Player", "Complete 5 team challenges"),
    ]
    s_data = [[
        Paragraph('<font color="#FFFFFF"><b>Badge Name</b></font>', styles['TableHeader']),
        Paragraph('<font color="#FFFFFF"><b>Requirement</b></font>', styles['TableHeader']),
    ]]
    for name, req in social_badges:
        s_data.append([Paragraph(f'<b>{name}</b>', styles['TableCell']), Paragraph(req, styles['TableCell'])])
    s_table = Table(s_data, colWidths=[150, 310])
    s_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), RED),
        ('BACKGROUND', (0, 1), (-1, -1), LIGHT_RED),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6), ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(s_table)
    story.append(Spacer(1, 12))

    story.append(Paragraph("Special & Rare Badges", styles['SubSection']))
    special = [
        ("Holiday Logger", "Log food on Christmas, Diwali, or New Year"),
        ("Early Bird", "Log breakfast before 6am"),
        ("Night Owl", "Log a midnight snack"),
        ("AI Explorer", "Use AI coach 20 times"),
        ("Scale Master", "Connect and use BLE smart scale 10 times"),
        ("New Year Resolution", "Log food every day in January"),
        ("Birthday Logger", "Log food on your birthday"),
        ("Completionist", "Earn 25 other badges"),
        ("Perfectionist", "Hit calorie target for 30 consecutive days"),
    ]
    sp_data = [[
        Paragraph('<font color="#FFFFFF"><b>Badge Name</b></font>', styles['TableHeader']),
        Paragraph('<font color="#FFFFFF"><b>Requirement</b></font>', styles['TableHeader']),
    ]]
    for name, req in special:
        sp_data.append([Paragraph(f'<b>{name}</b>', styles['TableCell']), Paragraph(req, styles['TableCell'])])
    sp_table = Table(sp_data, colWidths=[150, 310])
    sp_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), DARK),
        ('BACKGROUND', (0, 1), (-1, -1), LIGHT_GRAY),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6), ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(sp_table)
    story.append(Spacer(1, 16))

    story.append(Paragraph("XP & Level System", styles['SubSection']))
    story.append(Paragraph(
        "Every action earns XP: log food (10 XP), hit calorie target (50 XP), earn badge (100 XP), "
        "win challenge (200 XP), complete streak week (150 XP). Users level up from 1 to 50 with titles:",
        styles['BodyText2']
    ))
    level_data = [
        [Paragraph('<font color="#FFFFFF"><b>Level</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Title</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>XP Required</b></font>', styles['TableHeader'])],
        [Paragraph("1-5", styles['TableCellCenter']), Paragraph("Beginner", styles['TableCell']), Paragraph("0 - 500", styles['TableCellCenter'])],
        [Paragraph("6-10", styles['TableCellCenter']), Paragraph("Health Curious", styles['TableCell']), Paragraph("500 - 2,000", styles['TableCellCenter'])],
        [Paragraph("11-20", styles['TableCellCenter']), Paragraph("Nutrition Enthusiast", styles['TableCell']), Paragraph("2,000 - 8,000", styles['TableCellCenter'])],
        [Paragraph("21-30", styles['TableCellCenter']), Paragraph("Wellness Warrior", styles['TableCell']), Paragraph("8,000 - 20,000", styles['TableCellCenter'])],
        [Paragraph("31-40", styles['TableCellCenter']), Paragraph("Health Expert", styles['TableCell']), Paragraph("20,000 - 50,000", styles['TableCellCenter'])],
        [Paragraph("41-49", styles['TableCellCenter']), Paragraph("Nutrition Master", styles['TableCell']), Paragraph("50,000 - 100,000", styles['TableCellCenter'])],
        [Paragraph("50", styles['TableCellCenter']), Paragraph("<b>FoodSense Legend</b>", styles['TableCell']), Paragraph("100,000+", styles['TableCellCenter'])],
    ]
    level_table = Table(level_data, colWidths=[80, 200, 180])
    level_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), GREEN),
        ('BACKGROUND', (0, 1), (-1, -1), LIGHT_GREEN),
        ('BACKGROUND', (0, 7), (-1, 7), HexColor("#FEF3C7")),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6), ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(level_table)

    story.append(PageBreak())

    # ========== PART 4: AI FEATURES ==========
    story.append(colored_box("PART 4: AI FEATURES", PURPLE))
    story.append(Spacer(1, 16))

    story.append(Paragraph("Camera & Vision AI", styles['SubSection']))
    ai_vision = [
        (1, "Portion Size Estimation", "AI analyzes the photo with a reference object (plate, coin, hand) to estimate food weight in grams. Uses depth estimation and known object sizes.", True, "High"),
        (2, "Multi-Dish Breakdown", "Point camera at a full thali/plate. AI identifies and separates each dish with per-item nutrition. Uses segmentation models.", True, "High"),
        (3, "Before/After Plate Analysis", "Photo before eating, photo after. AI calculates actual consumption based on leftover analysis using image differencing.", True, "High"),
        (4, "Ingredient Detection", "AI identifies individual ingredients inside a dish (e.g., biryani = rice + chicken + spices + oil) for granular nutrition accuracy.", True, "High"),
        (5, "Freshness Detection", "Scan fruits/vegetables. AI estimates freshness level (fresh/ripe/overripe) and days until expiry using color and texture analysis.", True, "Medium"),
        (6, "Calorie Density Heatmap", "AR overlay on camera showing which parts of the plate are calorie-dense (red) vs light (green). Real-time visual feedback.", False, "High"),
        (7, "Food Quality Score", "AI rates each meal 1-10 on nutritional quality considering balance, processing level, micronutrient density, and variety.", True, "Medium"),
        (8, "Packaged Food OCR", "Scan the front of any packaged food. AI reads the nutrition label via OCR and extracts all info without needing a barcode.", True, "Medium"),
        (9, "Cooking Method Detection", "AI identifies if food is fried, grilled, steamed, or raw. Adjusts calorie estimate accordingly (frying adds ~120 kcal).", True, "Medium"),
        (10, "Beverage Detection", "Detect drinks (chai, juice, smoothie, soda) and estimate sugar/calorie content based on volume and type.", True, "Medium"),
    ]
    for num, title, desc, server, complexity in ai_vision:
        for f in feature_block(num, title, desc, complexity, server):
            story.append(f)

    story.append(PageBreak())

    story.append(Paragraph("Conversational AI", styles['SubSection']))
    ai_conv = [
        (11, "Voice Food Logging", "Say 'I had 2 rotis, dal, and buttermilk'. AI parses quantities, items, and logs everything. Uses speech-to-text + Gemini NLU.", True, "High"),
        (12, "Natural Language Queries", "Ask 'How much protein did I eat this week?' or 'What was my highest calorie day?' AI queries your data and answers in plain English.", True, "Medium"),
        (13, "AI Nutritionist Chat", "Full conversational AI dietitian that knows your complete history, goals, allergies, and preferences. Persistent context across sessions.", True, "High"),
        (14, "Explain My Food", "Tap any logged food. AI explains why it's healthy/unhealthy, key nutrients it provides, and suggests healthier alternatives.", True, "Low"),
        (15, "Mood-Based Recommendations", "Tell the AI how you feel (tired, bloated, energetic, stressed). It suggests specific foods backed by nutritional science.", True, "Medium"),
        (16, "Cultural Context AI", "Understands Indian food culture: dal-chawal as complete protein, accounts for ghee in cooking, recognizes regional dishes from all states.", True, "Medium"),
    ]
    for num, title, desc, server, complexity in ai_conv:
        for f in feature_block(num, title, desc, complexity, server):
            story.append(f)

    story.append(Paragraph("Predictive & Analytical AI", styles['SubSection']))
    ai_predict = [
        (17, "Weight Prediction", "Based on eating patterns and activity trends, AI predicts weight at 30/60/90 days. Visualized as a trend chart with confidence bands.", True, "Medium"),
        (18, "Binge Pattern Detection", "AI identifies emotional eating patterns (late night, weekends, stress periods). Sends early warnings and suggests coping strategies.", True, "Medium"),
        (19, "Nutrient Gap Predictor", "'At your current diet, you'll be deficient in Vitamin D and Iron within 2 months.' Proactive health warnings.", True, "Medium"),
        (20, "Optimal Meal Timing", "AI analyzes when you eat vs energy levels and sleep quality. Suggests ideal meal timing personalized to your body.", True, "Medium"),
        (21, "Metabolic Rate Learning", "AI learns your actual metabolic rate by correlating food intake with weight changes over weeks. Refines calorie budget dynamically.", True, "High"),
        (22, "Sleep-Nutrition Correlation", "AI finds connections: 'You sleep 40 minutes less on days you have coffee after 3pm' or 'Heavy dinners correlate with poor sleep.'", True, "Medium"),
        (23, "Cheat Day Optimizer", "AI calculates how to offset a high-calorie day across the week without crash dieting. Maintains weekly average.", True, "Low"),
        (24, "Grocery Spending Estimator", "Based on meal plan, AI estimates weekly grocery cost and suggests budget-friendly nutritional substitutes.", True, "Medium"),
    ]
    for num, title, desc, server, complexity in ai_predict:
        for f in feature_block(num, title, desc, complexity, server):
            story.append(f)

    story.append(PageBreak())

    story.append(Paragraph("Meal Planning AI", styles['SubSection']))
    ai_meal = [
        (25, "One-Tap Meal Plan", "AI generates a full week meal plan matching calorie budget, macro goals, cuisine preference, dietary restrictions, and budget constraints.", True, "High"),
        (26, "Smart Leftovers", "Tell AI what's in your fridge. It suggests complete meals you can make with available ingredients, minimizing food waste.", True, "Medium"),
        (27, "Prep-Ahead Suggestions", "AI identifies which meals from your plan can be batch-cooked on Sunday. Generates prep schedule and storage instructions.", True, "Medium"),
        (28, "Family Meal Optimizer", "Input family members' individual goals. AI creates meals that satisfy everyone's nutritional needs from a single cooking session.", True, "High"),
        (29, "Festival/Occasion Planner", "AI suggests healthier versions of festival foods: Diwali sweets, Eid biryani, Christmas dinner. Preserves taste, reduces calories.", True, "Medium"),
        (30, "Restaurant Menu Advisor", "Share a restaurant menu photo. AI highlights best options for your goals and warns about hidden calories in specific dishes.", True, "Medium"),
    ]
    for num, title, desc, server, complexity in ai_meal:
        for f in feature_block(num, title, desc, complexity, server):
            story.append(f)

    story.append(Paragraph("Fitness & Health AI", styles['SubSection']))
    ai_fitness = [
        (31, "Workout-Nutrition Sync", "AI adjusts meal plan based on today's workout: leg day = more protein, cardio = more carbs, rest day = maintenance calories.", True, "Medium"),
        (32, "Pre/Post Workout Meals", "AI suggests optimal pre-workout (energy) and post-workout (recovery) foods based on exercise type, intensity, and timing.", True, "Low"),
        (33, "Hydration AI", "Calculates personalized daily water needs based on weight, activity level, weather/temperature, and caffeine intake.", True, "Low"),
        (34, "Supplement Advisor", "Based on dietary gaps identified over weeks, AI recommends supplements (B12, Omega-3, D3) with dosage and timing.", True, "Medium"),
        (35, "Period Cycle Nutrition", "AI adjusts recommendations based on menstrual cycle phase: iron-rich foods during periods, magnesium for PMS, etc.", True, "Medium"),
        (36, "Diabetic Mode", "Monitors glycemic load of every meal. Warns about blood sugar spikes. Suggests low-GI alternatives. Tracks HbA1c-friendly patterns.", True, "High"),
        (37, "Blood Pressure Diet", "Tracks sodium intake across all meals. Suggests DASH diet adjustments. Alerts when daily sodium exceeds 2300mg.", True, "Medium"),
    ]
    for num, title, desc, server, complexity in ai_fitness:
        for f in feature_block(num, title, desc, complexity, server):
            story.append(f)

    story.append(PageBreak())

    story.append(Paragraph("AI Gamification", styles['SubSection']))
    ai_game = [
        (38, "AI Food Quiz", "Daily nutrition quiz generated by AI: 'Which has more protein: paneer or chicken?' Earn XP for correct answers. Difficulty adapts to your level.", True, "Low"),
        (39, "Nutrition IQ Score", "AI tests your food knowledge over time. Score grows as you learn. Compare with friends. Topics: macros, vitamins, cooking methods.", True, "Medium"),
        (40, "AI-Generated Challenges", "Personalized weekly challenges based on your weak spots: 'You've been low on fiber. Eat 3 high-fiber foods today.' Auto-difficulty scaling.", True, "Medium"),
        (41, "Food Detective Game", "AI shows a food photo, you guess the calories. Closer guess = more points. Learn portion estimation through play.", True, "Low"),
        (42, "Myth Buster", "AI presents common food myths daily ('Eating after 8pm makes you fat') and explains the scientific truth. Swipe-based interaction.", True, "Low"),
    ]
    for num, title, desc, server, complexity in ai_game:
        for f in feature_block(num, title, desc, complexity, server):
            story.append(f)

    story.append(Paragraph("Advanced AI", styles['SubSection']))
    ai_advanced = [
        (43, "Digital Twin Nutrition", "AI builds a digital model of your body. Simulates how different diets would affect health over months. 'What if' scenario planning.", True, "High"),
        (44, "Gut Health Score", "Estimates gut health based on fiber diversity, fermented food intake, processed food ratio. Tracks microbiome-friendly eating.", True, "Medium"),
        (45, "Inflammation Tracker", "Monitors foods linked to inflammation (refined sugar, trans fats, processed meat). Daily inflammation score with trend analysis.", True, "Medium"),
        (46, "Allergy Risk Detection", "AI notices frequent consumption of common allergens. Suggests getting tested if user reports symptoms like bloating or skin issues.", True, "Medium"),
        (47, "AI Food Pairing", "Suggests nutrient-boosting combinations: 'Add lemon to spinach. Vitamin C increases iron absorption by 6x.' Science-backed pairings.", True, "Low"),
        (48, "Circadian Nutrition", "Aligns meal suggestions with circadian rhythm for optimal digestion, energy, and sleep. Time-aware recommendations.", True, "Medium"),
        (49, "Personalized Glycemic Response", "AI learns that YOUR body responds differently to certain foods. Some people spike more from rice than bread. Builds personal GI profile.", True, "High"),
        (50, "Health Report for Doctor", "AI generates a professional PDF nutrition report you can share with your doctor or dietitian. Includes trends, gaps, and recommendations.", True, "Medium"),
    ]
    for num, title, desc, server, complexity in ai_advanced:
        for f in feature_block(num, title, desc, complexity, server):
            story.append(f)

    story.append(PageBreak())

    # ========== PART 5: SERVER ARCHITECTURE ==========
    story.append(colored_box("PART 5: SERVER ARCHITECTURE", DARK))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "With social features, AI processing, and real-time challenges, a robust server backend is essential. "
        "Here is the recommended architecture:",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    arch_data = [
        [Paragraph('<font color="#FFFFFF"><b>Layer</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Technology</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Purpose</b></font>', styles['TableHeader'])],
        [Paragraph("API Gateway", styles['TableCell']), Paragraph("Firebase Cloud Functions / AWS API Gateway", styles['TableCell']), Paragraph("Rate limiting, auth, routing", styles['TableCell'])],
        [Paragraph("Auth", styles['TableCell']), Paragraph("Firebase Auth + Custom JWT", styles['TableCell']), Paragraph("User identity, tokens, social login", styles['TableCell'])],
        [Paragraph("Database", styles['TableCell']), Paragraph("Firestore + PostgreSQL (Supabase)", styles['TableCell']), Paragraph("User data, social graph, leaderboards", styles['TableCell'])],
        [Paragraph("Real-time", styles['TableCell']), Paragraph("Firestore Listeners / WebSockets", styles['TableCell']), Paragraph("Live leaderboards, challenge updates, feed", styles['TableCell'])],
        [Paragraph("AI/ML", styles['TableCell']), Paragraph("Gemini API + Cloud Vision + Cloud Run", styles['TableCell']), Paragraph("Food analysis, NLU, predictions, meal plans", styles['TableCell'])],
        [Paragraph("Storage", styles['TableCell']), Paragraph("Firebase Storage / Cloud Storage", styles['TableCell']), Paragraph("Food photos, achievement cards, recipes", styles['TableCell'])],
        [Paragraph("Push", styles['TableCell']), Paragraph("Firebase Cloud Messaging (FCM)", styles['TableCell']), Paragraph("Notifications, nudges, challenge alerts", styles['TableCell'])],
        [Paragraph("Analytics", styles['TableCell']), Paragraph("Firebase Analytics + BigQuery", styles['TableCell']), Paragraph("User behavior, retention, feature usage", styles['TableCell'])],
        [Paragraph("Cache", styles['TableCell']), Paragraph("Redis (Cloud Memorystore)", styles['TableCell']), Paragraph("Leaderboard caching, rate limiting, sessions", styles['TableCell'])],
        [Paragraph("Search", styles['TableCell']), Paragraph("Algolia / Typesense", styles['TableCell']), Paragraph("Food database search, recipe discovery", styles['TableCell'])],
    ]
    arch_table = Table(arch_data, colWidths=[80, 180, 200])
    arch_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), DARK),
        ('BACKGROUND', (0, 1), (-1, -1), LIGHT_GRAY),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6), ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(arch_table)
    story.append(Spacer(1, 20))

    story.append(Paragraph("API Endpoints Required", styles['SubSection']))
    api_endpoints = [
        ("POST /api/food/analyze", "Send photo for AI food detection + nutrition"),
        ("POST /api/food/voice-log", "Send audio for voice-based food logging"),
        ("GET /api/meal-plan", "Generate personalized meal plan"),
        ("POST /api/coach/chat", "AI nutritionist conversation"),
        ("GET /api/user/profile", "User profile with stats, level, badges"),
        ("POST /api/friends/add", "Send/accept friend request"),
        ("GET /api/feed", "Friends activity feed with pagination"),
        ("POST /api/challenges/create", "Create a new challenge"),
        ("GET /api/leaderboard/:type", "Get leaderboard (global/friends/city)"),
        ("POST /api/badges/check", "Check and award earned badges"),
        ("GET /api/insights/weekly", "Weekly nutrition report and trends"),
        ("POST /api/food/predict-weight", "Weight prediction based on patterns"),
    ]
    api_data = [
        [Paragraph('<font color="#FFFFFF"><b>Endpoint</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Description</b></font>', styles['TableHeader'])],
    ]
    for endpoint, desc in api_endpoints:
        api_data.append([
            Paragraph(f'<font face="Courier" size="8">{endpoint}</font>', styles['TableCell']),
            Paragraph(desc, styles['TableCell']),
        ])
    api_table = Table(api_data, colWidths=[220, 240])
    api_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), BLUE),
        ('BACKGROUND', (0, 1), (-1, -1), LIGHT_BLUE),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 5), ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(api_table)

    story.append(PageBreak())

    # ========== PART 6: IMPLEMENTATION PRIORITY ==========
    story.append(colored_box("PART 6: IMPLEMENTATION PRIORITY", GREEN))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "Recommended implementation order based on user retention impact, technical dependencies, and development effort:",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    priority_data = [
        [Paragraph('<font color="#FFFFFF"><b>Priority</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Feature</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Impact</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Effort</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Timeline</b></font>', styles['TableHeader'])],
        [Paragraph("1", styles['TableCellCenter']), Paragraph("<b>Voice Food Logging</b>", styles['TableCell']), Paragraph("Very High", styles['TableCellCenter']), Paragraph("2 weeks", styles['TableCellCenter']), Paragraph("Month 1", styles['TableCellCenter'])],
        [Paragraph("2", styles['TableCellCenter']), Paragraph("<b>AI Nutritionist Chat</b>", styles['TableCell']), Paragraph("Very High", styles['TableCellCenter']), Paragraph("2 weeks", styles['TableCellCenter']), Paragraph("Month 1", styles['TableCellCenter'])],
        [Paragraph("3", styles['TableCellCenter']), Paragraph("<b>XP & Level System</b>", styles['TableCell']), Paragraph("High", styles['TableCellCenter']), Paragraph("1 week", styles['TableCellCenter']), Paragraph("Month 1", styles['TableCellCenter'])],
        [Paragraph("4", styles['TableCellCenter']), Paragraph("<b>Badge Collection (40 badges)</b>", styles['TableCell']), Paragraph("High", styles['TableCellCenter']), Paragraph("2 weeks", styles['TableCellCenter']), Paragraph("Month 2", styles['TableCellCenter'])],
        [Paragraph("5", styles['TableCellCenter']), Paragraph("<b>Smart Meal Plans</b>", styles['TableCell']), Paragraph("Very High", styles['TableCellCenter']), Paragraph("3 weeks", styles['TableCellCenter']), Paragraph("Month 2", styles['TableCellCenter'])],
        [Paragraph("6", styles['TableCellCenter']), Paragraph("<b>Weekly Reports & Insights</b>", styles['TableCell']), Paragraph("High", styles['TableCellCenter']), Paragraph("2 weeks", styles['TableCellCenter']), Paragraph("Month 2", styles['TableCellCenter'])],
        [Paragraph("7", styles['TableCellCenter']), Paragraph("<b>Friends & Activity Feed</b>", styles['TableCell']), Paragraph("Very High", styles['TableCellCenter']), Paragraph("4 weeks", styles['TableCellCenter']), Paragraph("Month 3", styles['TableCellCenter'])],
        [Paragraph("8", styles['TableCellCenter']), Paragraph("<b>Challenges & Leaderboards</b>", styles['TableCell']), Paragraph("High", styles['TableCellCenter']), Paragraph("3 weeks", styles['TableCellCenter']), Paragraph("Month 3", styles['TableCellCenter'])],
        [Paragraph("9", styles['TableCellCenter']), Paragraph("<b>Food Quality Score</b>", styles['TableCell']), Paragraph("Medium", styles['TableCellCenter']), Paragraph("1 week", styles['TableCellCenter']), Paragraph("Month 3", styles['TableCellCenter'])],
        [Paragraph("10", styles['TableCellCenter']), Paragraph("<b>Weight Prediction</b>", styles['TableCell']), Paragraph("High", styles['TableCellCenter']), Paragraph("2 weeks", styles['TableCellCenter']), Paragraph("Month 4", styles['TableCellCenter'])],
        [Paragraph("11", styles['TableCellCenter']), Paragraph("<b>Premium Subscription</b>", styles['TableCell']), Paragraph("Critical", styles['TableCellCenter']), Paragraph("2 weeks", styles['TableCellCenter']), Paragraph("Month 4", styles['TableCellCenter'])],
        [Paragraph("12", styles['TableCellCenter']), Paragraph("<b>Multi-Dish Breakdown</b>", styles['TableCell']), Paragraph("High", styles['TableCellCenter']), Paragraph("3 weeks", styles['TableCellCenter']), Paragraph("Month 4", styles['TableCellCenter'])],
        [Paragraph("13", styles['TableCellCenter']), Paragraph("<b>Sleep-Nutrition Correlation</b>", styles['TableCell']), Paragraph("Medium", styles['TableCellCenter']), Paragraph("2 weeks", styles['TableCellCenter']), Paragraph("Month 5", styles['TableCellCenter'])],
        [Paragraph("14", styles['TableCellCenter']), Paragraph("<b>League System</b>", styles['TableCell']), Paragraph("High", styles['TableCellCenter']), Paragraph("2 weeks", styles['TableCellCenter']), Paragraph("Month 5", styles['TableCellCenter'])],
        [Paragraph("15", styles['TableCellCenter']), Paragraph("<b>Share Achievement Cards</b>", styles['TableCell']), Paragraph("Medium", styles['TableCellCenter']), Paragraph("1 week", styles['TableCellCenter']), Paragraph("Month 5", styles['TableCellCenter'])],
    ]
    pri_table = Table(priority_data, colWidths=[50, 175, 75, 75, 75])
    pri_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), GREEN),
        ('BACKGROUND', (0, 1), (-1, 3), HexColor("#DCFCE7")),
        ('BACKGROUND', (0, 4), (-1, 6), HexColor("#FEF3C7")),
        ('BACKGROUND', (0, 7), (-1, 9), HexColor("#DBEAFE")),
        ('BACKGROUND', (0, 10), (-1, 12), HexColor("#EDE9FE")),
        ('BACKGROUND', (0, 13), (-1, 15), HexColor("#FEE2E2")),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6), ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(pri_table)

    story.append(PageBreak())

    # ========== PART 7: TECH STACK ==========
    story.append(colored_box("PART 7: TECH STACK SUMMARY", DARK))
    story.append(Spacer(1, 16))

    tech_data = [
        [Paragraph('<font color="#FFFFFF"><b>Component</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>iOS</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Android</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Server</b></font>', styles['TableHeader'])],
        [Paragraph("<b>Language</b>", styles['TableCell']), Paragraph("Swift 5.9+", styles['TableCell']), Paragraph("Kotlin 1.8+", styles['TableCell']), Paragraph("Node.js / Python", styles['TableCell'])],
        [Paragraph("<b>UI</b>", styles['TableCell']), Paragraph("SwiftUI", styles['TableCell']), Paragraph("Jetpack Compose", styles['TableCell']), Paragraph("N/A", styles['TableCell'])],
        [Paragraph("<b>Architecture</b>", styles['TableCell']), Paragraph("MVVM", styles['TableCell']), Paragraph("MVVM", styles['TableCell']), Paragraph("Microservices", styles['TableCell'])],
        [Paragraph("<b>Database</b>", styles['TableCell']), Paragraph("CoreData", styles['TableCell']), Paragraph("Room", styles['TableCell']), Paragraph("Firestore + PostgreSQL", styles['TableCell'])],
        [Paragraph("<b>ML/AI</b>", styles['TableCell']), Paragraph("TFLite + Vision", styles['TableCell']), Paragraph("TFLite + ML Kit", styles['TableCell']), Paragraph("Gemini + Cloud Vision", styles['TableCell'])],
        [Paragraph("<b>Auth</b>", styles['TableCell']), Paragraph("Firebase Auth", styles['TableCell']), Paragraph("Firebase Auth", styles['TableCell']), Paragraph("Firebase Auth + JWT", styles['TableCell'])],
        [Paragraph("<b>Camera</b>", styles['TableCell']), Paragraph("AVFoundation", styles['TableCell']), Paragraph("CameraX", styles['TableCell']), Paragraph("N/A", styles['TableCell'])],
        [Paragraph("<b>Bluetooth</b>", styles['TableCell']), Paragraph("CoreBluetooth", styles['TableCell']), Paragraph("Android BLE", styles['TableCell']), Paragraph("N/A", styles['TableCell'])],
        [Paragraph("<b>Health</b>", styles['TableCell']), Paragraph("HealthKit", styles['TableCell']), Paragraph("Health Connect", styles['TableCell']), Paragraph("N/A", styles['TableCell'])],
        [Paragraph("<b>Push</b>", styles['TableCell']), Paragraph("UNNotification", styles['TableCell']), Paragraph("AlarmManager", styles['TableCell']), Paragraph("FCM", styles['TableCell'])],
        [Paragraph("<b>Widget</b>", styles['TableCell']), Paragraph("WidgetKit", styles['TableCell']), Paragraph("Glance", styles['TableCell']), Paragraph("N/A", styles['TableCell'])],
        [Paragraph("<b>CI/CD</b>", styles['TableCell']), Paragraph("GitHub Actions", styles['TableCell']), Paragraph("GitHub Actions", styles['TableCell']), Paragraph("Firebase Deploy", styles['TableCell'])],
        [Paragraph("<b>Hosting</b>", styles['TableCell']), Paragraph("N/A", styles['TableCell']), Paragraph("N/A", styles['TableCell']), Paragraph("Firebase / GCP / AWS", styles['TableCell'])],
    ]
    tech_table = Table(tech_data, colWidths=[80, 120, 120, 140])
    tech_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), DARK),
        ('BACKGROUND', (0, 1), (0, -1), HexColor("#F3F4F6")),
        ('BACKGROUND', (1, 1), (-1, -1), white),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 5), ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(tech_table)

    story.append(Spacer(1, 30))
    story.append(HRFlowable(width="100%", thickness=2, color=GREEN, spaceBefore=0, spaceAfter=16))
    story.append(Paragraph(
        "FoodSense Feature Roadmap  |  150+ Features  |  iOS + Android + Server",
        styles['FooterText']
    ))
    story.append(Paragraph(
        "Generated April 2026  |  Ready for Implementation",
        styles['FooterText']
    ))

    # Build
    doc.build(story, onFirstPage=add_page_number, onLaterPages=add_page_number)
    print(f"PDF generated: {OUTPUT_PATH}")


if __name__ == "__main__":
    build_pdf()
