#!/usr/bin/env python3
"""Generate the FoodSense 30-Day Organic Marketing Plan PDF."""

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable, KeepTogether
)
import os

OUTPUT = os.path.join(os.path.dirname(__file__), "FoodSense_30Day_Marketing_Plan.pdf")

# Colors
GREEN = HexColor("#16A34A")
GREEN_DARK = HexColor("#15803D")
GREEN_LIGHT = HexColor("#DCFCE7")
BLUE = HexColor("#2563EB")
BLUE_LIGHT = HexColor("#DBEAFE")
AMBER = HexColor("#D97706")
AMBER_LIGHT = HexColor("#FEF3C7")
PURPLE = HexColor("#7C3AED")
PURPLE_LIGHT = HexColor("#EDE9FE")
RED = HexColor("#DC2626")
RED_LIGHT = HexColor("#FEE2E2")
DARK = HexColor("#111827")
GRAY = HexColor("#6B7280")
GRAY_LIGHT = HexColor("#F3F4F6")
TEAL = HexColor("#0D9488")
TEAL_LIGHT = HexColor("#CCFBF1")
PINK = HexColor("#DB2777")
PINK_LIGHT = HexColor("#FCE7F3")

s = getSampleStyleSheet()

# Custom styles
def ps(name, **kw):
    defaults = {'fontName': 'Helvetica', 'fontSize': 10, 'leading': 14, 'textColor': DARK}
    defaults.update(kw)
    s.add(ParagraphStyle(name, **defaults))

ps('CoverTitle', fontSize=30, leading=36, fontName='Helvetica-Bold', alignment=TA_CENTER, spaceAfter=8)
ps('CoverSub', fontSize=16, leading=22, textColor=GREEN, fontName='Helvetica-Bold', alignment=TA_CENTER, spaceAfter=6)
ps('CoverDesc', fontSize=13, leading=18, textColor=GRAY, alignment=TA_CENTER, spaceAfter=30)
ps('H1', fontSize=22, leading=28, fontName='Helvetica-Bold', spaceBefore=20, spaceAfter=12)
ps('H2', fontSize=16, leading=22, fontName='Helvetica-Bold', textColor=GREEN_DARK, spaceBefore=16, spaceAfter=8)
ps('H3', fontSize=13, leading=18, fontName='Helvetica-Bold', spaceBefore=12, spaceAfter=6)
ps('Body', fontSize=10, leading=15, spaceAfter=6, alignment=TA_JUSTIFY)
ps('BodySmall', fontSize=9, leading=13, textColor=GRAY, spaceAfter=4)
ps('BulletItem', fontSize=10, leading=15, leftIndent=18, bulletIndent=6, spaceAfter=3)
ps('Prompt', fontSize=9, leading=13, fontName='Courier', textColor=HexColor("#1E40AF"), leftIndent=12, spaceAfter=4,
   backColor=HexColor("#EFF6FF"), borderPadding=6)
ps('Caption', fontSize=9, leading=13, fontName='Helvetica-Oblique', textColor=HexColor("#374151"), leftIndent=12, spaceAfter=4,
   backColor=HexColor("#F9FAFB"), borderPadding=6)
ps('DayTitle', fontSize=12, leading=16, fontName='Helvetica-Bold', spaceBefore=10, spaceAfter=4)
ps('TagLine', fontSize=9, leading=12, textColor=PURPLE, fontName='Helvetica-Bold', spaceAfter=2)
ps('TH', fontSize=9, leading=12, textColor=white, fontName='Helvetica-Bold', alignment=TA_CENTER)
ps('TC', fontSize=9, leading=12, alignment=TA_LEFT)
ps('TCC', fontSize=9, leading=12, alignment=TA_CENTER)
ps('Footer', fontSize=8, leading=10, textColor=GRAY, alignment=TA_CENTER)


def page_template(c, doc):
    c.saveState()
    c.setStrokeColor(GREEN)
    c.setLineWidth(3)
    c.line(0, A4[1] - 10, A4[0], A4[1] - 10)
    c.setFont('Helvetica', 8)
    c.setFillColor(GRAY)
    c.drawCentredString(A4[0]/2, 18*mm, f"FoodSense 30-Day Marketing Plan  |  Page {doc.page}")
    c.restoreState()


def colored_header(text, color):
    return Table([[Paragraph(text, s['H1'])]], colWidths=[460], rowHeights=[44],
        style=TableStyle([('BACKGROUND', (0,0), (-1,-1), color), ('TEXTCOLOR', (0,0), (-1,-1), white),
            ('ALIGN', (0,0), (-1,-1), 'CENTER'), ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
            ('ROUNDEDCORNERS', [8,8,8,8]), ('BOTTOMPADDING', (0,0), (-1,-1), 10), ('TOPPADDING', (0,0), (-1,-1), 10)]))


def day_block(day_num, title, platform, content_type, firefly_prompt, caption, hashtags, notes=None):
    """Create a complete day entry."""
    elements = []
    platform_colors = {
        'Instagram': PINK, 'YouTube Shorts': RED, 'Twitter/X': BLUE,
        'LinkedIn': HexColor("#0A66C2"), 'Reddit': HexColor("#FF4500"),
        'Instagram Reels': PINK, 'All Platforms': GREEN,
        'Instagram + Twitter': PINK, 'YouTube + Instagram': RED,
    }
    pc = platform_colors.get(platform, GREEN)

    # Day header
    day_data = [[
        Paragraph(f'<font color="#FFFFFF"><b>DAY {day_num}</b></font>', s['TH']),
        Paragraph(f'<font color="#FFFFFF"><b>{title}</b></font>', s['TH']),
        Paragraph(f'<font color="#FFFFFF"><b>{platform}</b></font>', s['TH']),
        Paragraph(f'<font color="#FFFFFF"><b>{content_type}</b></font>', s['TH']),
    ]]
    dt = Table(day_data, colWidths=[50, 200, 110, 100])
    dt.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), pc),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'), ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('ROUNDEDCORNERS', [6,6,0,0]),
        ('TOPPADDING', (0,0), (-1,-1), 6), ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ]))
    elements.append(dt)

    # Firefly prompt
    elements.append(Paragraph('<b>Firefly Prompt:</b>', s['H3']))
    elements.append(Paragraph(firefly_prompt, s['Prompt']))

    # Caption
    elements.append(Paragraph('<b>Caption:</b>', s['H3']))
    elements.append(Paragraph(caption, s['Caption']))

    # Hashtags
    elements.append(Paragraph(f'<b>Hashtags:</b> <font color="#7C3AED">{hashtags}</font>', s['BodySmall']))

    if notes:
        elements.append(Paragraph(f'<b>Tip:</b> <font color="#D97706">{notes}</font>', s['BodySmall']))

    elements.append(Spacer(1, 8))
    elements.append(HRFlowable(width="100%", thickness=0.5, color=HexColor("#E5E7EB"), spaceAfter=8))
    return elements


def build():
    doc = SimpleDocTemplate(OUTPUT, pagesize=A4,
        leftMargin=28*mm, rightMargin=28*mm, topMargin=24*mm, bottomMargin=24*mm)
    story = []

    # ===== COVER =====
    story.append(Spacer(1, 60))
    story.append(Paragraph("FoodSense", s['CoverTitle']))
    story.append(Paragraph("30-Day Organic Marketing Plan", s['CoverSub']))
    story.append(Spacer(1, 12))
    story.append(HRFlowable(width="30%", thickness=2, color=GREEN, spaceAfter=16))
    story.append(Paragraph(
        "Complete day-by-day content calendar with Adobe Firefly prompts,<br/>"
        "social media captions, hashtag strategies, and growth tactics.<br/>"
        "100% organic growth — zero ad spend.",
        s['CoverDesc']))
    story.append(Spacer(1, 24))

    # Stats
    stats = [
        [Paragraph('<font color="#FFF"><b>Platforms</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Content Pieces</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Firefly Prompts</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Strategy</b></font>', s['TH'])],
        [Paragraph('<font size="14"><b>5</b></font>', s['TCC']),
         Paragraph('<font size="14"><b>30+</b></font>', s['TCC']),
         Paragraph('<font size="14"><b>30</b></font>', s['TCC']),
         Paragraph('<font size="14"><b>100% Organic</b></font>', s['TCC'])],
    ]
    st = Table(stats, colWidths=[110]*4)
    st.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), GREEN),
        ('BACKGROUND', (0,1), (-1,1), GREEN_LIGHT),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'), ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, HexColor("#D1D5DB")),
        ('TOPPADDING', (0,1), (-1,1), 10), ('BOTTOMPADDING', (0,1), (-1,1), 10),
    ]))
    story.append(st)
    story.append(Spacer(1, 30))
    story.append(Paragraph("April 2026  |  Target: India + Global", s['CoverDesc']))
    story.append(PageBreak())

    # ===== TABLE OF CONTENTS =====
    story.append(Paragraph("Table of Contents", s['H1']))
    story.append(HRFlowable(width="100%", thickness=1, color=GREEN, spaceAfter=12))
    toc = [
        ("Part 1", "Marketing Strategy Overview"),
        ("Part 2", "Target Audience & Platforms"),
        ("Part 3", "Content Pillars & Themes"),
        ("Part 4", "Week 1 — Launch & Awareness (Days 1-7)"),
        ("Part 5", "Week 2 — Education & Value (Days 8-14)"),
        ("Part 6", "Week 3 — Social Proof & Community (Days 15-21)"),
        ("Part 7", "Week 4 — Conversion & Growth (Days 22-30)"),
        ("Part 8", "Hashtag Strategy & SEO"),
        ("Part 9", "Growth Hacks & Viral Tactics"),
        ("Part 10", "KPIs & Success Metrics"),
    ]
    for part, title in toc:
        story.append(Paragraph(f'<font color="#16A34A"><b>{part}</b></font>  {title}', s['Body']))
    story.append(PageBreak())

    # ===== PART 1: STRATEGY =====
    story.append(colored_header("PART 1: MARKETING STRATEGY", GREEN))
    story.append(Spacer(1, 12))

    story.append(Paragraph("Mission Statement", s['H2']))
    story.append(Paragraph(
        "Position FoodSense as India's most intelligent nutrition tracking app by building a community "
        "of health-conscious users through educational content, viral short-form video, and authentic user stories. "
        "Zero ad spend — pure organic growth through value-driven content.",
        s['Body']))

    story.append(Paragraph("Growth Strategy: The AIDA Framework", s['H2']))
    aida = [
        [Paragraph('<font color="#FFF"><b>Phase</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Week</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Goal</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Content Focus</b></font>', s['TH'])],
        [Paragraph('<b>Awareness</b>', s['TC']), Paragraph('Week 1', s['TCC']),
         Paragraph('Reach 50K impressions', s['TC']), Paragraph('Viral hooks, problem-aware content', s['TC'])],
        [Paragraph('<b>Interest</b>', s['TC']), Paragraph('Week 2', s['TCC']),
         Paragraph('1K followers', s['TC']), Paragraph('Feature demos, nutrition education', s['TC'])],
        [Paragraph('<b>Desire</b>', s['TC']), Paragraph('Week 3', s['TCC']),
         Paragraph('500 app downloads', s['TC']), Paragraph('User stories, before/after, social proof', s['TC'])],
        [Paragraph('<b>Action</b>', s['TC']), Paragraph('Week 4', s['TCC']),
         Paragraph('1K downloads, 100 DAU', s['TC']), Paragraph('CTAs, urgency, community challenges', s['TC'])],
    ]
    at = Table(aida, colWidths=[80, 60, 140, 180])
    at.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), GREEN),
        ('BACKGROUND', (0,1), (-1,1), GREEN_LIGHT),
        ('BACKGROUND', (0,2), (-1,2), BLUE_LIGHT),
        ('BACKGROUND', (0,3), (-1,3), AMBER_LIGHT),
        ('BACKGROUND', (0,4), (-1,4), PURPLE_LIGHT),
        ('GRID', (0,0), (-1,-1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 6), ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(at)
    story.append(Spacer(1, 10))

    story.append(Paragraph("Key Principles", s['H2']))
    principles = [
        "<b>80/20 Rule:</b> 80% value content (education, tips, entertainment), 20% promotional",
        "<b>Hook in 1 Second:</b> Every Reel/Short must grab attention in the first frame",
        "<b>Indian Context First:</b> Use Indian foods, Hindi+English captions, relatable scenarios",
        "<b>Consistency Over Perfection:</b> Post daily. Good enough today beats perfect next week",
        "<b>Community Building:</b> Reply to every comment in the first 30 days. Build superfans",
        "<b>Cross-Pollinate:</b> Repurpose every piece of content across all 5 platforms",
    ]
    for p in principles:
        story.append(Paragraph(p, s['BulletItem'], bulletText='\u2022'))
    story.append(PageBreak())

    # ===== PART 2: AUDIENCE =====
    story.append(colored_header("PART 2: TARGET AUDIENCE & PLATFORMS", BLUE))
    story.append(Spacer(1, 12))

    story.append(Paragraph("Primary Audience Segments", s['H2']))
    audience = [
        [Paragraph('<font color="#FFF"><b>Segment</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Age</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Motivation</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Content That Works</b></font>', s['TH'])],
        [Paragraph('<b>Fitness Enthusiasts</b>', s['TC']), Paragraph('18-30', s['TCC']),
         Paragraph('Track macros, build muscle, lose fat', s['TC']),
         Paragraph('Protein tracking, meal prep, before/after', s['TC'])],
        [Paragraph('<b>Health-Conscious Women</b>', s['TC']), Paragraph('22-35', s['TCC']),
         Paragraph('Healthy eating, weight management', s['TC']),
         Paragraph('Quick meals, calorie awareness, self-care', s['TC'])],
        [Paragraph('<b>Diabetic/Health Condition</b>', s['TC']), Paragraph('35-55', s['TCC']),
         Paragraph('Monitor sugar, control diet', s['TC']),
         Paragraph('GI tracking, meal suggestions, doctor reports', s['TC'])],
        [Paragraph('<b>Students/Young Pros</b>', s['TC']), Paragraph('18-25', s['TCC']),
         Paragraph('Affordable healthy eating', s['TC']),
         Paragraph('Budget meals, hostel food hacks, quick logging', s['TC'])],
        [Paragraph('<b>Parents</b>', s['TC']), Paragraph('28-40', s['TCC']),
         Paragraph('Family nutrition, kids\' health', s['TC']),
         Paragraph('Family meal plans, tiffin ideas, balanced nutrition', s['TC'])],
    ]
    aud_t = Table(audience, colWidths=[120, 40, 150, 150])
    aud_t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), BLUE),
        ('BACKGROUND', (0,1), (-1,-1), BLUE_LIGHT),
        ('GRID', (0,0), (-1,-1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 5), ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(aud_t)
    story.append(Spacer(1, 12))

    story.append(Paragraph("Platform Strategy", s['H2']))
    platforms = [
        [Paragraph('<font color="#FFF"><b>Platform</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Format</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Frequency</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Best Time (IST)</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Strategy</b></font>', s['TH'])],
        [Paragraph('<b>Instagram</b>', s['TC']), Paragraph('Reels, Stories, Carousels', s['TC']),
         Paragraph('Daily', s['TCC']), Paragraph('7-8am, 12-1pm, 7-9pm', s['TC']),
         Paragraph('Primary growth engine. Reels for reach, Stories for engagement', s['TC'])],
        [Paragraph('<b>YouTube Shorts</b>', s['TC']), Paragraph('Shorts (60s)', s['TC']),
         Paragraph('5x/week', s['TCC']), Paragraph('2-4pm, 8-10pm', s['TC']),
         Paragraph('Repurpose Reels. YouTube has longer shelf life', s['TC'])],
        [Paragraph('<b>Twitter/X</b>', s['TC']), Paragraph('Text, threads, images', s['TC']),
         Paragraph('2-3x/day', s['TCC']), Paragraph('8-9am, 1pm, 8pm', s['TC']),
         Paragraph('Nutrition hot takes, engage with fitness community', s['TC'])],
        [Paragraph('<b>LinkedIn</b>', s['TC']), Paragraph('Posts, articles', s['TC']),
         Paragraph('3x/week', s['TCC']), Paragraph('8-9am weekdays', s['TC']),
         Paragraph('Founder journey, startup story, product updates', s['TC'])],
        [Paragraph('<b>Reddit</b>', s['TC']), Paragraph('Posts, comments', s['TC']),
         Paragraph('3x/week', s['TCC']), Paragraph('Evening', s['TC']),
         Paragraph('r/IndianFood, r/fitness, r/loseit. Genuine value, no spam', s['TC'])],
    ]
    pl_t = Table(platforms, colWidths=[70, 100, 55, 80, 155])
    pl_t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), DARK),
        ('BACKGROUND', (0,1), (-1,-1), GRAY_LIGHT),
        ('GRID', (0,0), (-1,-1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 5), ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(pl_t)
    story.append(PageBreak())

    # ===== PART 3: CONTENT PILLARS =====
    story.append(colored_header("PART 3: CONTENT PILLARS & THEMES", PURPLE))
    story.append(Spacer(1, 12))

    pillars = [
        ("1. Shock & Educate", "Reveal hidden calories in everyday Indian foods. Surprise factor drives shares.",
         "\"Your daily chai has HOW many calories?!\" with a visual breakdown"),
        ("2. Demo & Wow", "Show the app in action — scan food, get instant nutrition. Tech amazement factor.",
         "Screen recording of scanning a thali and getting full nutrition breakdown in 2 seconds"),
        ("3. Myth Busting", "Debunk common food myths with science. Positions FoodSense as a trusted authority.",
         "\"Ghee is unhealthy\" — Actually, here's what nutritionists say..."),
        ("4. Relatable Humor", "Memes and funny scenarios about dieting, food guilt, and healthy eating struggles.",
         "POV: You open the app after a wedding buffet"),
        ("5. User Transformation", "Before/after stories, streak celebrations, personal health journeys.",
         "\"I tracked my food for 30 days and here's what changed\""),
        ("6. Quick Tips", "15-second actionable nutrition tips. High save and share rate.",
         "\"3 high-protein breakfasts under 300 calories\" with visuals"),
    ]
    for title, desc, example in pillars:
        story.append(Paragraph(title, s['H3']))
        story.append(Paragraph(desc, s['Body']))
        story.append(Paragraph(f'<i>Example: {example}</i>', s['BodySmall']))

    story.append(PageBreak())

    # ===== WEEK 1 =====
    story.append(colored_header("WEEK 1: LAUNCH & AWARENESS (Days 1-7)", GREEN))
    story.append(Spacer(1, 8))
    story.append(Paragraph("Goal: Generate buzz, establish presence, reach 50K impressions", s['Body']))
    story.append(Spacer(1, 6))

    # Day 1
    for el in day_block(1, "Launch Announcement", "All Platforms", "Image + Video",
        "A sleek smartphone floating against a gradient green background, showing a food scanning interface with colorful nutrition rings orbiting the screen, futuristic health tech aesthetic, clean minimal design, soft shadows, 4K product photography style",
        "We built an AI that can tell you exactly what's in your food. Just point your camera.\n\nIntroducing FoodSense - AI-powered nutrition tracking that works offline.\n\n- Snap a photo, get instant nutrition\n- 1000+ Indian foods in our database\n- Works without internet\n- Free to download\n\nLink in bio. Your health journey starts today.",
        "#FoodSense #LaunchDay #NutritionTracker #AIFood #HealthTech #IndianFood #CalorieCounter #FitnessIndia",
        "Post at 7pm IST for maximum reach. Pin this post to your profile."): story.append(el)

    # Day 2
    for el in day_block(2, "The Hidden Calories in Chai", "Instagram Reels", "Short Video (30s)",
        "A beautiful cup of masala chai with steam rising, split-screen showing the ingredients floating out: sugar cubes, milk drops, tea leaves, each labeled with calorie counts, warm kitchen background, food photography lighting, Indian aesthetic",
        "Your daily chai has more calories than you think.\n\nMasala chai with sugar: 120 kcal\nWith 2 biscuits: 280 kcal\n3 cups a day? That's 840 kcal. Almost half your daily budget.\n\nNot saying quit chai. Just know what you're drinking.\n\nScan your chai with FoodSense. It takes 2 seconds.",
        "#ChaiLovers #HiddenCalories #IndianDiet #NutritionFacts #FoodSense #CalorieAwareness #HealthyIndia",
        "Use trending audio. Text overlay with calorie reveals. This format gets high shares."): story.append(el)

    # Day 3
    for el in day_block(3, "App Demo — Scan a Thali", "YouTube Shorts", "Screen Recording + VO",
        "A traditional Indian thali with dal, rice, sabzi, roti, and raita arranged beautifully on a brass plate, overhead shot, warm lighting, rustic wooden table, authentic Indian home kitchen setting, food styling",
        "Can AI identify every dish on an Indian thali?\n\nWe pointed FoodSense at a full thali and... it got everything.\n\nDal: 180 kcal, 12g protein\nRice: 200 kcal\n2 Rotis: 240 kcal\nAloo Sabzi: 150 kcal\n\nTotal: 770 kcal with full macro breakdown.\n\nDownload FoodSense. It knows Indian food.",
        "#IndianThali #FoodAI #NutritionScanner #IndianFood #TechIndia #FoodSense #HealthyEating",
        "Screen record the actual app scanning food. Authentic > polished."): story.append(el)

    # Day 4
    for el in day_block(4, "Myth Buster — Roti vs Rice", "Instagram + Twitter", "Carousel / Thread",
        "Side-by-side comparison graphic: a golden roti on the left and a bowl of white rice on the right, both on a clean white background with nutritional info floating around them like holographic labels, modern infographic style, vibrant colors",
        "Roti vs Rice — Which is actually healthier?\n\nSlide 1: The debate that never ends\nSlide 2: 1 Roti = 120 kcal, 3g protein, 20g carbs\nSlide 3: 1 cup Rice = 200 kcal, 4g protein, 45g carbs\nSlide 4: But here's what matters more — PORTION SIZE\nSlide 5: Both are fine. Track your portions, not your fears.\n\nStop demonizing food. Start understanding it.\nFoodSense helps you track, not restrict.",
        "#RotiVsRice #NutritionMyth #IndianDiet #MythBuster #FoodSense #HealthyEating #DietTips #Fitness",
        "Twitter thread version: one point per tweet. End with app CTA."): story.append(el)

    story.append(PageBreak())

    # Day 5
    for el in day_block(5, "POV Meme — Wedding Buffet", "Instagram Reels", "Meme Video (15s)",
        "A grand Indian wedding buffet table overflowing with colorful dishes: butter chicken, biryani, gulab jamun, naan, paneer tikka, viewed from a person's perspective looking overwhelmed, dramatic lighting, cinematic Indian wedding atmosphere, rich gold and red decorations",
        "POV: You open FoodSense after the shaadi buffet\n\n*scans plate*\n\nCalories: 2,847\nProtein: 45g\nCarbs: 380g\nFat: 120g\n\nWorth it? Absolutely.\nBack on track tomorrow? Also absolutely.\n\nNo guilt. Just data. That's FoodSense.",
        "#ShaadiBuffet #IndianWedding #FoodMeme #CalorieCounter #NoFoodGuilt #FoodSense #RelateableContent",
        "Use a trending Bollywood audio. The humor drives shares."): story.append(el)

    # Day 6
    for el in day_block(6, "3 High-Protein Breakfasts", "YouTube Shorts", "Tips Video (45s)",
        "Three Indian breakfast plates arranged in a row on a clean marble surface: scrambled eggs with paratha, paneer bhurji with toast, moong dal chilla with chutney, each with a glowing protein count floating above, bright morning lighting, food photography",
        "3 high-protein Indian breakfasts under 350 calories:\n\n1. Moong Dal Chilla + Chutney\n   28g protein | 280 kcal\n\n2. Paneer Bhurji + 1 Toast\n   22g protein | 320 kcal\n\n3. 2 Egg Omelette + Roti\n   24g protein | 340 kcal\n\nSave this. Your morning gains sorted.\n\nTrack them instantly with FoodSense.",
        "#HighProtein #IndianBreakfast #ProteinBreakfast #FitnessFood #MealPrep #FoodSense #HealthyMorning",
        "This format (numbered tips with visuals) has the highest save rate on Instagram."): story.append(el)

    # Day 7
    for el in day_block(7, "Week 1 Recap + Streak Challenge", "All Platforms", "Story + Post",
        "A glowing streak counter showing '7 days' with fire emojis and confetti, green and gold color scheme, gamification UI design, achievement unlocked style graphic, celebration vibes, dark background with vibrant accents",
        "Day 7 of using FoodSense. Here's what happened:\n\n- Logged 21 meals\n- Discovered my chai was 840 kcal/day\n- Hit my protein goal 5 out of 7 days\n- Lost 0.5 kg without starving\n\nThe first week is the hardest. But now I can't stop checking.\n\nStart your 7-day streak. It's free.\n\n#7DayChallenge: Track every meal this week. Tag @FoodSense. Best transformation wins a shoutout.",
        "#7DayChallenge #FoodSense #StreakChallenge #NutritionTracking #HealthJourney #TransformationChallenge",
        "Launch the challenge hashtag. Engage with EVERY response. This seeds your community."): story.append(el)

    story.append(PageBreak())

    # ===== WEEK 2 =====
    story.append(colored_header("WEEK 2: EDUCATION & VALUE (Days 8-14)", BLUE))
    story.append(Spacer(1, 8))
    story.append(Paragraph("Goal: Establish authority, drive app downloads, reach 1K followers", s['Body']))
    story.append(Spacer(1, 6))

    for el in day_block(8, "Maggi Nutrition Breakdown", "Instagram Reels", "Shock Reveal (20s)",
        "A packet of instant noodles being poured into a bowl with steam, then a dramatic freeze-frame showing floating nutritional labels: sodium, carbs, and fat counts appearing like warning signs, dark moody lighting, food documentary style",
        "1 packet of Maggi. Let's scan it.\n\nCalories: 420\nSodium: 1,600mg (67% daily limit!)\nCarbs: 58g\nProtein: 9g\nFat: 17g\n\nNot saying don't eat it. But maybe not daily.\n\nKnowledge is power. FoodSense gives you the data.\n\nWhat food should we scan next? Comment below.",
        "#Maggi #InstantNoodles #CalorieBomb #SodiumAlert #FoodSense #NutritionFacts #IndianSnacks",
        "Ask 'what should I scan next?' to drive comments and algorithm boost."): story.append(el)

    for el in day_block(9, "Protein Ranking — Indian Foods", "Instagram Carousel", "Infographic",
        "A colorful ranking chart showing Indian foods arranged by protein content: paneer, chicken, eggs, dal, soya chunks, chole, with each food photographed beautifully next to its protein count, clean white background, modern data visualization, vibrant food colors",
        "Top 10 Indian foods ranked by protein per 100g:\n\n1. Soya Chunks — 52g\n2. Chicken Breast — 31g\n3. Paneer — 18g\n4. Eggs — 13g\n5. Chana — 19g\n6. Moong Dal — 24g\n7. Rajma — 22g\n8. Fish (Rohu) — 17g\n9. Curd — 11g\n10. Tofu — 8g\n\nSave this list. Share with someone who needs it.\n\nTrack your protein with FoodSense.",
        "#ProteinFoods #IndianProtein #GymDiet #ProteinRanking #FoodSense #MacroTracking #FitnessIndia",
        "Carousel posts get saved more than any other format. High-value lists = growth."): story.append(el)

    for el in day_block(10, "How the AI Actually Works", "YouTube Shorts", "Explainer (55s)",
        "A smartphone screen showing a neural network visualization processing a food image, with nodes and connections lighting up as the AI identifies different food items, sci-fi tech aesthetic with green accent colors, futuristic but friendly, clean dark background",
        "How does FoodSense identify food with AI? Here's the real tech:\n\n1. You take a photo\n2. Our YOLOv8 model (running ON your phone) identifies foods in milliseconds\n3. No internet needed - works offline\n4. For detailed nutrition, Gemini AI analyzes ingredients, cooking method, portion size\n5. Matched against 1000+ Indian food database\n\nResult: Full nutrition in under 3 seconds.\n\nThis isn't magic. It's engineering.",
        "#AITech #MachineLearning #FoodAI #TechExplainer #FoodSense #YOLOv8 #DeepLearning #IndianTech",
        "Tech explainers build trust with the 'how does it work?' crowd."): story.append(el)

    for el in day_block(11, "Office Lunch Calories", "Instagram Reels", "Relatable (25s)",
        "A typical Indian office lunch scene: dabba/tiffin box with rice, dal, sabzi on a desk next to a laptop, with floating calorie labels appearing one by one, modern office setting, warm natural lighting, day-in-the-life aesthetic",
        "Your average office lunch, scanned:\n\nRice + Dal + Sabzi = 550 kcal\nBut add:\n- Ghee on rice: +120 kcal\n- 2 Rotis instead: +240 kcal\n- Afternoon chai + biscuit: +180 kcal\n\nTotal: 850-1,100 kcal\n\nThat's potentially half your daily budget in one meal.\n\nNot bad, not good. Just data. Track it with FoodSense.",
        "#OfficeLunch #Dabba #CorporateLife #CalorieCount #IndianOffice #FoodSense #LunchBreak",
        "Tag office life pages and food bloggers for potential shares."): story.append(el)

    story.append(PageBreak())

    for el in day_block(12, "Founder Story — Why I Built This", "LinkedIn", "Personal Post",
        "A developer's workspace with dual monitors showing code and a food detection interface, a smartphone showing the FoodSense app, warm desk lamp lighting, coffee cup, notebook with sketches, authentic indie developer aesthetic, motivational startup vibes",
        "I built an AI that scans your food and tells you the nutrition.\n\nNot because I'm a nutritionist. Because I'm an engineer who was tired of guessing.\n\nEvery Indian meal I ate — dal, roti, sabzi — I had no idea how much protein I was getting. Apps existed for Western food. Nothing worked for Indian cuisine.\n\nSo I trained a model on 95 food classes. Built an offline-first app. Added 1000+ Indian foods to the database.\n\nFoodSense is now live on iOS and Android.\n\nBuilding in public. Shipping from India.",
        "#BuildInPublic #StartupIndia #FounderStory #IndianStartup #FoodTech #HealthTech #FoodSense",
        "LinkedIn founder stories get massive organic reach. Be authentic, not salesy."): story.append(el)

    for el in day_block(13, "Cheat Day Calculator", "Instagram + Twitter", "Interactive Post",
        "A fun infographic showing popular cheat day foods: pizza, biryani, ice cream, samosa, with their calorie counts arranged like a menu board, playful colorful design, retro diner aesthetic with Indian twist, bold typography",
        "Build your cheat day. What's the damage?\n\nPizza slice: 250 kcal\nBiryani (1 plate): 500 kcal\nGulab Jamun (2): 300 kcal\nCold Coffee: 350 kcal\nSamosa (2): 400 kcal\nIce Cream (1 scoop): 200 kcal\n\nComment your cheat day combo. I'll calculate the total.\n\nNo judgment. Just math.",
        "#CheatDay #CalorieCalculator #FoodMath #NoGuilt #WeekendVibes #FoodSense #IndianFood #GuiltFree",
        "Reply to EVERY comment with a calorie calculation. This drives massive engagement."): story.append(el)

    for el in day_block(14, "Mid-Month Progress Report", "All Platforms", "Story + Carousel",
        "A progress dashboard showing metrics going up: downloads graph, user count, streak data, with a celebratory green and gold color scheme, data visualization style, clean modern UI, milestone achievement graphic",
        "2 weeks of FoodSense. Here's what our community tracked:\n\n- 5,000+ foods scanned\n- Average user logs 3 meals/day\n- Most scanned food: Dal Rice (obviously)\n- Longest streak: 14 days and counting\n- Most shocking discovery: Chai = 840 kcal/day\n\nYou're part of something. Keep tracking.\n\n#FoodSenseFamily — share your streak!",
        "#FoodSenseFamily #2WeekUpdate #CommunityGrowth #NutritionTracking #MilestoneUnlocked #FoodSense",
        "Share real metrics (or projected). Transparency builds trust."): story.append(el)

    story.append(PageBreak())

    # ===== WEEK 3 =====
    story.append(colored_header("WEEK 3: SOCIAL PROOF & COMMUNITY (Days 15-21)", AMBER))
    story.append(Spacer(1, 8))
    story.append(Paragraph("Goal: Build community, generate UGC, reach 500 downloads", s['Body']))
    story.append(Spacer(1, 6))

    for el in day_block(15, "User Spotlight — First Transformation", "Instagram Reels", "Testimonial (30s)",
        "A split-screen before/after transformation graphic with a person's meal tracking journey: left side showing chaotic eating, right side showing organized colorful meals with nutrition data overlaid, motivational fitness aesthetic, green accent colors, inspirational vibes",
        "\"I didn't change what I ate. I just started tracking.\"\n\nMeet our first FoodSense user who completed 14 days:\n\n- Realized breakfast was only 12g protein\n- Added eggs — protein jumped to 28g\n- Discovered evening snacks were 600 kcal\n- Swapped biscuits for makhana\n- Lost 1.5 kg in 2 weeks\n\nNo diet. No restriction. Just awareness.\n\nStart tracking. The data will change your behavior.",
        "#TransformationStory #FoodSense #NoRestrictiveDiet #AwarenessIsKey #HealthJourney #UserSpotlight",
        "Use a real user if possible. If not, use your own tracking data."): story.append(el)

    for el in day_block(16, "Samosa vs Protein Bar", "YouTube Shorts", "Comparison (20s)",
        "A golden crispy samosa on one side and a protein bar on the other, placed on a balance scale, dramatic lighting from above casting shadows, food duel aesthetic, versus battle graphic style, vibrant Indian and fitness fusion",
        "Samosa vs Protein Bar — which is better?\n\nSamosa (1 pc):\n- 250 kcal, 4g protein, 14g fat\n\nProtein Bar:\n- 200 kcal, 20g protein, 7g fat\n\nBut the samosa costs Rs 15.\nThe protein bar costs Rs 150.\n\nBetter option? 2 boiled eggs:\n- 140 kcal, 12g protein, 10g fat, Rs 16.\n\nStop buying expensive supplements. Eat smart.",
        "#SamosaVsProteinBar #BudgetProtein #IndianFitness #SmartEating #FoodSense #ProteinOnBudget",
        "Controversial comparisons drive debate in comments = algorithm boost."): story.append(el)

    for el in day_block(17, "Day in My Life — Tracking Edition", "Instagram Reels", "Vlog Style (55s)",
        "A lifestyle flat lay showing a day's worth of Indian meals arranged clockwise: morning chai and paratha, lunch dabba, evening fruits, dinner dal rice, with a smartphone showing FoodSense app at the center, overhead shot, natural daylight, cozy home aesthetic",
        "Everything I ate today, tracked with FoodSense:\n\n7am: Chai + Paratha — 380 kcal\n10am: Banana + Almonds — 200 kcal\n1pm: Dal Rice + Sabzi — 550 kcal\n4pm: Chai + Makhana — 180 kcal\n8pm: Roti + Paneer — 420 kcal\n\nTotal: 1,730 kcal | 68g protein\n\nGoal was 1,800. Pretty close.\n\nTracking doesn't take effort once it's a habit. 30 seconds per meal.",
        "#DayInMyLife #FoodDiary #CalorieTracking #IndianMeals #FullDayOfEating #FoodSense #TrackYourFood",
        "This format is extremely popular. Film actual meals, show the app scanning each."): story.append(el)

    for el in day_block(18, "Street Food Calorie Guide", "Instagram Carousel", "Infographic",
        "A vibrant collage of Indian street foods: pani puri, vada pav, chole bhature, dosa, pav bhaji, each in its own frame with calorie counts as price tags, street market background with colorful lights, festive Indian street food photography",
        "Indian Street Food Calorie Guide:\n\n- Pani Puri (6 pcs): 200 kcal\n- Vada Pav: 290 kcal\n- Chole Bhature: 650 kcal\n- Dosa (masala): 350 kcal\n- Pav Bhaji: 450 kcal\n- Jalebi (2 pcs): 300 kcal\n- Momos (6 pcs): 350 kcal\n\nSave this for your next street food adventure.\n\nScan any food with FoodSense for instant calories.",
        "#StreetFood #IndianStreetFood #CalorieGuide #FoodSense #PaniPuri #VadaPav #StreetFoodCalories",
        "Street food content is viral in India. Save + share rate is very high."): story.append(el)

    story.append(PageBreak())

    for el in day_block(19, "Reddit AMA — Building an AI Food App", "Reddit", "AMA Post",
        "No Firefly visual needed — text-based Reddit post",
        "Title: I built an AI app that scans your food and tells you the nutrition — AMA\n\nPost:\nHey r/IndianFood (and r/fitness),\n\nI'm an indie developer from India. I built FoodSense — an app that uses on-device AI to identify food from a photo and give you full nutrition info.\n\nThe model runs locally (no internet needed). I trained it on 95 food classes including Indian foods like biryani, dosa, and dal rice.\n\nThe app is free on iOS and Android.\n\nAMA about: the tech, nutrition data accuracy, building an AI model, indie development, anything!\n\n---\n\n(Be genuine. Reddit hates marketing. Lead with value.)",
        "r/IndianFood r/fitness r/loseit r/IndianGaming r/developersIndia r/startups",
        "Reddit AMAs can drive 500+ downloads if done right. Be authentic and technical."): story.append(el)

    for el in day_block(20, "Bollywood Food Scenes Scanned", "Instagram Reels", "Entertainment (30s)",
        "A dramatic recreation of a classic Bollywood feast scene with a table full of Indian dishes in a grand dining room setting, with a modern smartphone overlay scanning the food, mixing vintage Bollywood glamour with modern tech, cinematic golden lighting",
        "What if we scanned Bollywood food scenes?\n\n\"Baahubali\" feast: ~3,500 kcal\n\"Lunchbox\" dabba: ~650 kcal (actually balanced!)\n\"The Kashmir Files\" wazwan: ~4,200 kcal\n\"Band Baaja Baaraat\" wedding: Calories cannot be computed\n\nBollywood understands one thing: food is love.\n\nBut love should come with nutrition info.\n\nFoodSense: Because even filmy food has calories.",
        "#Bollywood #FoodInMovies #BollywoodFood #FunnyFood #FoodSense #IndianCinema #Calories",
        "Pop culture references drive insane engagement. Tag Bollywood fan pages."): story.append(el)

    for el in day_block(21, "End of Week 3 — Community Challenge Results", "All Platforms", "Post + Stories",
        "A collection of user streak screenshots arranged in a mosaic pattern with gold star badges, community celebration graphic, confetti elements, FoodSense brand green, user-generated content collage style, diverse happy people celebrating health wins",
        "3 weeks of #FoodSenseFamily. The numbers:\n\n- 14 people completed the 7-day challenge\n- 3 users hit 21-day streaks\n- Most scanned: Dal Rice, Chai, Paratha\n- Best discovery: \"I was eating 300 kcal of ghee daily without knowing\"\n\nNEW CHALLENGE: 30-Day Streak Challenge\n\nTrack every meal for 30 days. Share your dashboard.\nBest transformation gets featured + FoodSense merch.\n\nTag a friend who needs this.",
        "#FoodSenseFamily #30DayChallenge #CommunityChallenge #StreakChallenge #HealthCommunity #FoodSense",
        "Announce the 30-day challenge. This creates a retention loop."): story.append(el)

    story.append(PageBreak())

    # ===== WEEK 4 =====
    story.append(colored_header("WEEK 4: CONVERSION & GROWTH (Days 22-30)", DARK))
    story.append(Spacer(1, 8))
    story.append(Paragraph("Goal: Drive 1K downloads, 100 daily active users, seed viral loop", s['Body']))
    story.append(Spacer(1, 6))

    for el in day_block(22, "Festival Food Guide — Navratri/Ramadan", "Instagram Carousel", "Seasonal Content",
        "A beautifully arranged Navratri fasting thali with sabudana khichdi, kuttu roti, fruit, dry fruits on a decorated brass plate, with festive marigold flowers and diyas, warm golden festival lighting, traditional Indian celebration aesthetic",
        "Festival Fasting? Track it right.\n\nNavratri/Fasting Food Calories:\n- Sabudana Khichdi: 350 kcal\n- Kuttu Roti + Aloo: 280 kcal\n- Fruit Salad: 150 kcal\n- Makhana (roasted): 90 kcal\n- Singhara Atta Puri: 400 kcal\n\nFasting doesn't mean low calorie. Some fasting foods are higher than regular meals.\n\nTrack your festival meals with FoodSense.",
        "#NavratriFood #FastingDiet #FestivalFood #IndianFestivals #HealthyFasting #FoodSense #Vrat",
        "Seasonal/festival content gets massive reach. Time this with actual festivals."): story.append(el)

    for el in day_block(23, "How to Read Food Labels", "YouTube Shorts", "Education (50s)",
        "A hand holding a packaged food product (biscuit packet) with magnified nutritional label, annotations pointing out hidden sugars, serving size tricks, and misleading claims, investigative documentary style, sharp focus on the label details",
        "Food companies don't want you to read this.\n\n3 label tricks they use:\n\n1. 'Per serving' = tiny portion nobody eats\n   (That cookie pack? 3 servings = 3x the calories shown)\n\n2. 'Sugar-free' = loaded with artificial sweeteners\n   (Check the ingredient list, not the front label)\n\n3. 'Multigrain' does NOT mean healthy\n   (First ingredient is usually refined flour)\n\nFoodSense reads labels for you. Just scan the barcode.",
        "#FoodLabels #PackagedFood #HiddenSugars #ConsumerAwareness #FoodSense #ReadTheLabel #SmartShopping",
        "Consumer awareness content builds trust and shareability."): story.append(el)

    for el in day_block(24, "Influencer Collaboration — Fitness Creator", "Instagram Reels", "Collab (40s)",
        "Two phones side by side showing different fitness tracking apps, with FoodSense highlighted on one, gym/fitness setting in background, motivational workout atmosphere, collaboration between two creators, dynamic split-screen energy",
        "Collab with @[fitness_creator]:\n\n\"I asked [creator] to scan their entire meal prep with FoodSense.\n\nTheir reaction? 'Wait, it works for Indian food too?!'\n\nScanned:\n- Chicken breast + rice: 450 kcal, 42g protein\n- Paneer tikka: 320 kcal, 24g protein\n- Protein smoothie: 280 kcal, 35g protein\n\nTotal: 1,050 kcal, 101g protein. Solid prep.\n\nBuilt for Indian food. Built for Indian fitness.\"",
        "#FitnessCollab #MealPrep #IndianFitness #ProteinMeals #FoodSense #GymFood #Collaboration",
        "Reach out to 10 micro-influencers (5K-50K followers). Offer free premium features."): story.append(el)

    for el in day_block(25, "Dark Side of Diet Culture", "Twitter/X Thread", "Thought Leadership",
        "No Firefly visual — text thread on Twitter",
        "Thread: Why calorie counting gets a bad reputation (and what we're doing differently)\n\n1/ Most calorie trackers make you feel guilty. Enter a 'cheat meal' and you see red warnings everywhere. That's toxic.\n\n2/ At FoodSense, we show data with ZERO judgment. No red. No warnings. No 'you exceeded your limit.'\n\n3/ The goal isn't restriction. It's awareness. When you know your daily chai is 840 kcal, you can make informed choices.\n\n4/ We don't have a food 'guilt meter.' We have a nutrition dashboard. There's a difference.\n\n5/ The Indian diet is already nutritious. Dal-chawal is a complete protein. Ghee has good fats. We celebrate Indian food.\n\n6/ FoodSense: Know your food. Love your food. No guilt required.\n\n7/ Free on iOS and Android. Link below.",
        "#DietCulture #NoFoodGuilt #HealthyRelationshipWithFood #FoodSense #MentalHealth #NutritionAwareness",
        "Threads that challenge mainstream views get massive RT. Be bold."): story.append(el)

    story.append(PageBreak())

    for el in day_block(26, "Budget Meal Plan — Rs 100/day", "Instagram Carousel", "Value Content",
        "A colorful budget meal plan layout showing breakfast, lunch, dinner with prices next to each item, Indian thali style arrangement, clean white background with rupee symbols, affordable healthy eating infographic, bright and inviting",
        "Healthy eating on Rs 100/day. Here's a full meal plan:\n\nBreakfast (Rs 25): 2 Eggs + 1 Toast\n- 280 kcal, 18g protein\n\nLunch (Rs 40): Dal + Rice + Seasonal Sabzi\n- 550 kcal, 15g protein\n\nSnack (Rs 10): Roasted Chana (50g)\n- 180 kcal, 10g protein\n\nDinner (Rs 25): 2 Roti + Curd + Aloo\n- 400 kcal, 12g protein\n\nTotal: Rs 100 | 1,410 kcal | 55g protein\n\nHealthy eating isn't expensive. It's a myth.\n\nTrack your budget meals with FoodSense.",
        "#BudgetMeals #HealthyOnBudget #Rs100 #IndianMealPlan #CheapAndHealthy #FoodSense #StudentLife",
        "Budget content resonates with students and young professionals. Very high share rate."): story.append(el)

    for el in day_block(27, "Compare: FoodSense vs MyFitnessPal", "YouTube Shorts", "Comparison",
        "Two smartphone screens side by side: one showing a generic western food tracking app struggling with Indian food, the other showing FoodSense correctly identifying dal rice with detailed nutrition, Indian food focus, head-to-head comparison style",
        "I scanned Indian food with 2 apps. Here's what happened:\n\nMyFitnessPal:\n- Couldn't find 'dal tadka'\n- Manual entry took 3 minutes\n- No Indian food photos\n- Nutrition data was US-based\n\nFoodSense:\n- Scanned in 2 seconds\n- Identified dal, rice, and sabzi\n- Indian nutrient database\n- Works offline\n\nBuilt for Indian food. By an Indian developer.\n\nFree on iOS and Android.",
        "#FoodSenseVsMFP #AppComparison #IndianFoodTracker #BetterAlternative #FoodSense #MadeInIndia",
        "Competitor comparison content is high intent. People searching for alternatives will find this."): story.append(el)

    for el in day_block(28, "User-Generated Content Showcase", "All Platforms", "Community",
        "A mosaic grid of diverse smartphone screenshots showing different users' FoodSense dashboards with various Indian meals scanned, variety of streaks and badges earned, community collage, colorful and diverse, celebration of real users",
        "Our community is incredible. Look at these scans from real users:\n\n@user1 — Scanned an entire Rajasthani thali\n@user2 — 28-day streak and counting\n@user3 — Discovered they were eating 200g protein/day\n@user4 — Tracking family meals for their diabetic father\n\nEvery scan teaches you something about your food.\n\nShare your FoodSense screenshot with #FoodSenseFamily. We'll feature the best ones!",
        "#FoodSenseFamily #UserSpotlight #CommunityLove #RealUsers #FoodSense #UGC #HealthCommunity",
        "Repost user content. People love being featured. This creates a viral loop."): story.append(el)

    for el in day_block(29, "One Month Data Revealed", "Instagram Reels + LinkedIn", "Data Story",
        "A cinematic data visualization showing 30 days of nutrition data transforming from chaos to clarity: messy food photos on one side morphing into clean organized charts and graphs on the other, green glow effect, data science meets food, modern tech aesthetic",
        "30 days of data. Here's what FoodSense users discovered:\n\n- Average Indian eats 2,200 kcal/day (goal is usually 1,800-2,000)\n- Biggest calorie source: cooking oil (average 400 kcal/day from oil alone)\n- Protein gap: most users get only 40g/day (need 55-70g)\n- Chai contributes 15% of daily calories\n- Weekend calories are 40% higher than weekdays\n\nThis data only exists because people tracked. Start your data journey.\n\nFoodSense. Free. Offline. Indian.",
        "#30DayData #NutritionInsights #IndianDietData #FoodSense #DataDriven #HealthInsights #TrackToKnow",
        "Data reveals are shareable because they're surprising and credible."): story.append(el)

    for el in day_block(30, "Thank You + What's Next", "All Platforms", "Milestone Post",
        "A celebration graphic with '30 DAYS' in bold, confetti and streamers in green and gold, FoodSense logo prominently displayed, milestone achievement unlocked style, vibrant energetic celebratory mood, community thank you message",
        "30 days ago, FoodSense was just an idea on your phone.\n\nToday:\n- 1,000+ downloads\n- 50,000+ foods scanned\n- 100+ daily active users\n- Community across 5 platforms\n\nBut this is just the beginning. Coming soon:\n- Voice logging (just say what you ate)\n- AI meal plans\n- Friends & challenges\n- Weekly nutrition reports\n\nThank you for believing in us. Thank you for tracking.\n\nThe first 30 days are yours. The next 30 are ours to earn.\n\n#FoodSenseForever",
        "#FoodSense #30Days #ThankYou #MadeInIndia #HealthTech #AppLaunch #CommunityFirst #IndianStartup",
        "Be genuinely grateful. This post sets the tone for month 2."): story.append(el)

    story.append(PageBreak())

    # ===== PART 8: HASHTAGS =====
    story.append(colored_header("PART 8: HASHTAG STRATEGY", TEAL))
    story.append(Spacer(1, 12))

    story.append(Paragraph("Hashtag Tiers (use 5-8 per post)", s['H2']))
    ht_data = [
        [Paragraph('<font color="#FFF"><b>Tier</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Volume</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Hashtags</b></font>', s['TH'])],
        [Paragraph('<b>Brand</b>', s['TC']), Paragraph('0-1K', s['TCC']),
         Paragraph('#FoodSense #FoodSenseFamily #FoodSenseApp #FoodSenseIndia', s['TC'])],
        [Paragraph('<b>Niche</b>', s['TC']), Paragraph('1K-50K', s['TCC']),
         Paragraph('#IndianNutrition #DesiDiet #IndianCalories #FoodScannerApp #AIFoodDetection', s['TC'])],
        [Paragraph('<b>Medium</b>', s['TC']), Paragraph('50K-500K', s['TCC']),
         Paragraph('#CalorieCounter #MacroTracking #NutritionFacts #HealthyIndian #FitnessIndia', s['TC'])],
        [Paragraph('<b>Broad</b>', s['TC']), Paragraph('500K+', s['TCC']),
         Paragraph('#HealthyEating #Fitness #IndianFood #HealthTech #WeightLoss #GymLife', s['TC'])],
    ]
    ht = Table(ht_data, colWidths=[60, 60, 340])
    ht.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), TEAL),
        ('BACKGROUND', (0,1), (-1,-1), TEAL_LIGHT),
        ('GRID', (0,0), (-1,-1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 6), ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(ht)
    story.append(Spacer(1, 16))

    story.append(Paragraph("SEO Keywords for App Store / Blog", s['H2']))
    seo_kw = [
        "ai food scanner app", "calorie counter indian food", "nutrition tracker india",
        "food detection app", "scan food get calories", "indian diet tracker",
        "offline calorie counter", "best nutrition app india", "food calorie calculator",
        "macro tracker indian food", "healthy indian diet plan", "protein in indian food",
    ]
    story.append(Paragraph("Primary keywords: " + ", ".join(seo_kw[:6]), s['Body']))
    story.append(Paragraph("Long-tail keywords: " + ", ".join(seo_kw[6:]), s['Body']))
    story.append(PageBreak())

    # ===== PART 9: GROWTH HACKS =====
    story.append(colored_header("PART 9: GROWTH HACKS & VIRAL TACTICS", PINK))
    story.append(Spacer(1, 12))

    hacks = [
        ("1. The Comment Calculator", "On every food-related viral post, comment: 'Just scanned this with FoodSense. That plate is approximately 1,200 kcal with 35g protein.' People will ask 'what app is that?' Provide value first, pitch second."),
        ("2. Collaboration Chain", "DM 20 micro-influencers (5K-50K followers) in fitness/food niches. Offer: 'I'll scan your entire meal prep for free and create a nutrition breakdown post for your audience.' Free content for them, exposure for you."),
        ("3. Reddit Value Bombing", "Find every 'how many calories in...' post on r/IndianFood, r/fitness, r/loseit. Answer with detailed nutrition info and casually mention 'I used FoodSense to calculate this.' Provide value, don't spam."),
        ("4. The Streak Screenshot Challenge", "Ask users to screenshot their streak and share on Stories tagging @FoodSense. Repost every single one. People love being featured. This creates FOMO."),
        ("5. Quora Answer Engine", "Answer nutrition questions on Quora with detailed, helpful responses. Include FoodSense screenshots as proof. Quora answers rank on Google for years."),
        ("6. Cross-Promotion with Fitness Apps", "Partner with workout apps, meditation apps, or health blogs. 'Complete your health stack: [Workout App] for exercise + FoodSense for nutrition.' Exchange shoutouts."),
        ("7. Meme Jacking", "When food memes go viral, create a FoodSense version. 'When the meme is relatable but the calories aren't' + scanned result. Ride the viral wave."),
        ("8. The Email Signature Hack", "Add 'I track my food with FoodSense — foodsense.app' to your email signature. Every email you send becomes a micro-ad."),
        ("9. WhatsApp Status Marketing", "Create shareable nutrition infographics sized for WhatsApp Status (1080x1920). People share health tips in family groups. This is how Indian apps go viral."),
        ("10. Product Hunt Launch", "Submit to Product Hunt with a compelling story. IndieHackers community loves 'built by one developer' stories. Can drive 500+ downloads in one day."),
    ]
    for title, desc in hacks:
        story.append(Paragraph(title, s['H3']))
        story.append(Paragraph(desc, s['Body']))

    story.append(PageBreak())

    # ===== PART 10: KPIs =====
    story.append(colored_header("PART 10: KPIs & SUCCESS METRICS", DARK))
    story.append(Spacer(1, 12))

    kpi_data = [
        [Paragraph('<font color="#FFF"><b>Metric</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Week 1</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Week 2</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Week 3</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Week 4</b></font>', s['TH'])],
        [Paragraph('<b>Instagram Followers</b>', s['TC']),
         Paragraph('200', s['TCC']), Paragraph('500', s['TCC']), Paragraph('1,000', s['TCC']), Paragraph('2,000', s['TCC'])],
        [Paragraph('<b>Total Impressions</b>', s['TC']),
         Paragraph('50K', s['TCC']), Paragraph('150K', s['TCC']), Paragraph('300K', s['TCC']), Paragraph('500K', s['TCC'])],
        [Paragraph('<b>App Downloads</b>', s['TC']),
         Paragraph('100', s['TCC']), Paragraph('300', s['TCC']), Paragraph('500', s['TCC']), Paragraph('1,000', s['TCC'])],
        [Paragraph('<b>Daily Active Users</b>', s['TC']),
         Paragraph('30', s['TCC']), Paragraph('50', s['TCC']), Paragraph('75', s['TCC']), Paragraph('100', s['TCC'])],
        [Paragraph('<b>Avg Engagement Rate</b>', s['TC']),
         Paragraph('5%', s['TCC']), Paragraph('6%', s['TCC']), Paragraph('7%', s['TCC']), Paragraph('8%', s['TCC'])],
        [Paragraph('<b>User Streak (avg days)</b>', s['TC']),
         Paragraph('3', s['TCC']), Paragraph('5', s['TCC']), Paragraph('7', s['TCC']), Paragraph('10', s['TCC'])],
        [Paragraph('<b>UGC Posts</b>', s['TC']),
         Paragraph('5', s['TCC']), Paragraph('15', s['TCC']), Paragraph('30', s['TCC']), Paragraph('50', s['TCC'])],
    ]
    kpi_t = Table(kpi_data, colWidths=[130, 82, 82, 82, 82])
    kpi_t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), DARK),
        ('BACKGROUND', (1,1), (1,-1), GREEN_LIGHT),
        ('BACKGROUND', (2,1), (2,-1), BLUE_LIGHT),
        ('BACKGROUND', (3,1), (3,-1), AMBER_LIGHT),
        ('BACKGROUND', (4,1), (4,-1), PURPLE_LIGHT),
        ('BACKGROUND', (0,1), (0,-1), GRAY_LIGHT),
        ('GRID', (0,0), (-1,-1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 6), ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(kpi_t)
    story.append(Spacer(1, 20))

    story.append(Paragraph("Daily Routine (30 minutes/day)", s['H2']))
    routine = [
        [Paragraph('<font color="#FFF"><b>Time</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Task</b></font>', s['TH']),
         Paragraph('<font color="#FFF"><b>Duration</b></font>', s['TH'])],
        [Paragraph('Morning', s['TC']), Paragraph('Create content (Firefly visual + caption)', s['TC']), Paragraph('15 min', s['TCC'])],
        [Paragraph('Morning', s['TC']), Paragraph('Post on primary platform', s['TC']), Paragraph('2 min', s['TCC'])],
        [Paragraph('Afternoon', s['TC']), Paragraph('Cross-post to other platforms', s['TC']), Paragraph('3 min', s['TCC'])],
        [Paragraph('Afternoon', s['TC']), Paragraph('Reply to all comments + DMs', s['TC']), Paragraph('5 min', s['TCC'])],
        [Paragraph('Evening', s['TC']), Paragraph('Engage on 10 relevant posts (comment value)', s['TC']), Paragraph('5 min', s['TCC'])],
    ]
    rt = Table(routine, colWidths=[70, 290, 100])
    rt.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), GREEN),
        ('BACKGROUND', (0,1), (-1,-1), GREEN_LIGHT),
        ('GRID', (0,0), (-1,-1), 0.5, HexColor("#D1D5DB")),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 6), ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(rt)
    story.append(Spacer(1, 24))

    story.append(HRFlowable(width="100%", thickness=2, color=GREEN, spaceAfter=12))
    story.append(Paragraph("FoodSense 30-Day Marketing Plan  |  100% Organic  |  30 Firefly Prompts  |  30 Captions", s['Footer']))
    story.append(Paragraph("Generated April 2026  |  Execute Daily. Measure Weekly. Iterate Monthly.", s['Footer']))

    doc.build(story, onFirstPage=page_template, onLaterPages=page_template)
    print(f"PDF generated: {OUTPUT}")


if __name__ == "__main__":
    build()
