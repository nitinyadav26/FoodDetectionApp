#!/usr/bin/env python3
"""Generate the FoodSense Deployment & Publishing Guide PDF."""

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

OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "FoodSense_Deployment_Guide.pdf")

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
    name='StepTitle', fontSize=11, leading=15, textColor=DARK,
    fontName='Helvetica-Bold', spaceBefore=4, spaceAfter=2
))
styles.add(ParagraphStyle(
    name='StepDesc', fontSize=10, leading=14, textColor=GRAY,
    fontName='Helvetica', spaceBefore=0, spaceAfter=6, alignment=TA_JUSTIFY
))
styles.add(ParagraphStyle(
    name='BodyText2', fontSize=10, leading=14, textColor=DARK,
    fontName='Helvetica', spaceBefore=2, spaceAfter=4, alignment=TA_JUSTIFY
))
styles.add(ParagraphStyle(
    name='CodeBlock', fontSize=9, leading=13, textColor=DARK,
    fontName='Courier', spaceBefore=4, spaceAfter=8, leftIndent=12,
    backColor=LIGHT_GRAY
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
styles.add(ParagraphStyle(
    name='BulletItem', fontSize=10, leading=14, textColor=DARK,
    fontName='Helvetica', spaceBefore=2, spaceAfter=2, leftIndent=20,
    bulletIndent=8, alignment=TA_LEFT
))
styles.add(ParagraphStyle(
    name='WarningText', fontSize=10, leading=14, textColor=HexColor("#92400E"),
    fontName='Helvetica-Bold', spaceBefore=4, spaceAfter=4, leftIndent=8
))


def add_page_number(canvas_obj, doc):
    """Add page number and footer to each page."""
    canvas_obj.saveState()
    canvas_obj.setFont('Helvetica', 8)
    canvas_obj.setFillColor(GRAY)
    canvas_obj.drawCentredString(A4[0] / 2, 20 * mm,
                                 f"FoodSense Deployment Guide  |  Page {doc.page}")
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
    return HRFlowable(width="100%", thickness=1, color=HexColor("#E5E7EB"),
                      spaceBefore=12, spaceAfter=12)


def step_block(number, title, description):
    """Create a formatted step entry."""
    elements = []
    elements.append(Paragraph(
        f'<font color="#16A34A">{number}.</font> {title}',
        styles['StepTitle']
    ))
    elements.append(Paragraph(description, styles['StepDesc']))
    return elements


def bullet_list(items):
    """Create a list of bullet-pointed items."""
    elements = []
    for item in items:
        elements.append(Paragraph(f"\u2022  {item}", styles['BulletItem']))
    return elements


def code_block(text):
    """Create a styled code block."""
    return Paragraph(f"<font face='Courier' size='9'>{text}</font>",
                     styles['CodeBlock'])


def info_box(text, bg_color=LIGHT_BLUE):
    """Create an info/warning box."""
    return Table(
        [[Paragraph(text, styles['BodyText2'])]],
        colWidths=[440],
        style=TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), bg_color),
            ('ROUNDEDCORNERS', [6, 6, 6, 6]),
            ('LEFTPADDING', (0, 0), (-1, -1), 12),
            ('RIGHTPADDING', (0, 0), (-1, -1), 12),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ])
    )


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
    story.append(Paragraph("Deployment &amp; Publishing Guide", ParagraphStyle(
        'CoverSub', parent=styles['DocSubtitle'], fontSize=18, textColor=GREEN
    )))
    story.append(Spacer(1, 20))
    story.append(HRFlowable(width="40%", thickness=2, color=GREEN,
                            spaceBefore=0, spaceAfter=20))
    story.append(Paragraph(
        "Server Deployment on DigitalOcean<br/>"
        "iOS App Store &amp; Google Play Store Submission<br/>"
        "Domain, SSL, Firebase &amp; Monitoring Setup",
        styles['DocSubtitle']
    ))
    story.append(Spacer(1, 40))

    # Overview stats box
    stats_data = [
        [Paragraph('<font color="#FFFFFF"><b>Chapters</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Platforms</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Services</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Est. Time</b></font>', styles['TableHeader'])],
        [Paragraph('<font size="16"><b>8</b></font>', styles['TableCellCenter']),
         Paragraph('<font size="16"><b>3</b></font>', styles['TableCellCenter']),
         Paragraph('<font size="16"><b>6+</b></font>', styles['TableCellCenter']),
         Paragraph('<font size="16"><b>2-3h</b></font>', styles['TableCellCenter'])],
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
        ("Chapter 1", "Prerequisites", "3"),
        ("Chapter 2", "DigitalOcean Droplet Setup", "4"),
        ("Chapter 3", "Server Deployment", "6"),
        ("Chapter 4", "Domain + SSL Configuration", "8"),
        ("Chapter 5", "Firebase Configuration", "10"),
        ("Chapter 6", "iOS App Store Submission", "12"),
        ("Chapter 7", "Google Play Store Submission", "14"),
        ("Chapter 8", "Monitoring &amp; Maintenance", "16"),
        ("Appendix", "Environment Variables Reference", "18"),
    ]
    for part, title, page in toc_items:
        story.append(Paragraph(
            f'<font color="#16A34A"><b>{part}</b></font>  '
            f'{title} <font color="#9CA3AF">{"." * 60}</font> {page}',
            styles['TOCItem']
        ))
    story.append(PageBreak())

    # ========== CHAPTER 1: PREREQUISITES ==========
    story.append(colored_box("CHAPTER 1: PREREQUISITES", GREEN))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "Before beginning deployment, ensure you have all required accounts, "
        "credentials, and tools ready. Missing any of these will block the process.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    story.append(Paragraph("Accounts &amp; Subscriptions", styles['SubSection']))
    for e in bullet_list([
        "<b>DigitalOcean Account</b> -- Cloud hosting for the backend server. "
        "Credit card required. A $6/mo Basic Droplet is sufficient to start.",
        "<b>Domain Name</b> -- A registered domain (e.g., foodsense.app) from any registrar "
        "(Namecheap, Google Domains, Cloudflare, etc.).",
        "<b>Firebase Project</b> -- Google Firebase project with Authentication (Email/Password + Anonymous) "
        "and Firebase Cloud Messaging (FCM) enabled.",
        "<b>Gemini API Key</b> -- Google AI Studio API key for the Gemini model used by the AI coach and food detection.",
        "<b>Apple Developer Program</b> -- $99/year membership required for App Store distribution. "
        "Enrollment takes up to 48 hours for approval.",
        "<b>Google Play Developer Account</b> -- One-time $25 registration fee. "
        "Account activation may take up to 48 hours.",
    ]):
        story.append(e)

    story.append(Paragraph("Local Tools &amp; Software", styles['SubSection']))
    for e in bullet_list([
        "<b>Git</b> -- Version control. Ensure SSH keys are configured for the repository.",
        "<b>Docker &amp; Docker Compose</b> -- Container runtime for the server stack. "
        "Docker Desktop (macOS/Windows) or Docker Engine (Linux).",
        "<b>Xcode 15+</b> -- Required for iOS builds. Must be signed in with your Apple Developer account.",
        "<b>Android Studio</b> -- Required for Android builds. Ensure JDK 17+ and Gradle are configured.",
        "<b>Node.js 18+ &amp; npm</b> -- For running server locally during development/testing.",
    ]):
        story.append(e)

    story.append(section_divider())
    story.append(info_box(
        "<b>Tip:</b> Create a secure document listing all credentials (API keys, passwords, "
        "signing certificates) before starting. Never commit secrets to version control."
    ))
    story.append(PageBreak())

    # ========== CHAPTER 2: DIGITALOCEAN DROPLET SETUP ==========
    story.append(colored_box("CHAPTER 2: DIGITALOCEAN DROPLET SETUP", BLUE))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "Set up an Ubuntu server on DigitalOcean to host the FoodSense backend API, "
        "database, and Redis cache.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    story.append(Paragraph("Create Droplet", styles['SubSection']))
    for e in step_block("1", "Create a new Droplet",
        "Log in to DigitalOcean and click <b>Create Droplet</b>. "
        "Select <b>Ubuntu 22.04 LTS</b> as the image."):
        story.append(e)
    for e in step_block("2", "Choose Plan",
        "Select <b>Basic &gt; Regular (SSD)</b> with at least <b>2 GB RAM / 1 vCPU / 50 GB SSD</b> "
        "($12/mo). For production with multiple users, consider 4 GB RAM."):
        story.append(e)
    for e in step_block("3", "Add SSH Key",
        "Upload your public SSH key (~/.ssh/id_rsa.pub or id_ed25519.pub). "
        "This is required for secure server access. Password auth should be disabled."):
        story.append(e)
    for e in step_block("4", "Select Region",
        "Choose the datacenter closest to your primary user base for lowest latency. "
        "Enable monitoring and backups for production."):
        story.append(e)

    story.append(Paragraph("Initial Server Configuration", styles['SubSection']))
    for e in step_block("5", "SSH into the server",
        "Connect via <font face='Courier'>ssh root@YOUR_DROPLET_IP</font>. "
        "On first login, update all packages."):
        story.append(e)
    story.append(code_block("apt update &amp;&amp; apt upgrade -y"))
    story.append(Spacer(1, 4))

    for e in step_block("6", "Configure UFW Firewall",
        "Enable the firewall and allow only necessary ports:"):
        story.append(e)
    story.append(code_block(
        "ufw allow OpenSSH<br/>"
        "ufw allow 80/tcp<br/>"
        "ufw allow 443/tcp<br/>"
        "ufw enable"
    ))
    story.append(Spacer(1, 4))

    for e in step_block("7", "Install Docker &amp; Docker Compose",
        "Install Docker Engine and the Compose plugin:"):
        story.append(e)
    story.append(code_block(
        "curl -fsSL https://get.docker.com | sh<br/>"
        "apt install -y docker-compose-plugin<br/>"
        "docker --version<br/>"
        "docker compose version"
    ))
    story.append(Spacer(1, 4))

    for e in step_block("8", "Create a non-root user (recommended)",
        "Create a deploy user with Docker group access for better security:"):
        story.append(e)
    story.append(code_block(
        "adduser deploy<br/>"
        "usermod -aG docker deploy<br/>"
        "usermod -aG sudo deploy"
    ))
    story.append(PageBreak())

    # ========== CHAPTER 3: SERVER DEPLOYMENT ==========
    story.append(colored_box("CHAPTER 3: SERVER DEPLOYMENT", DARK_GREEN))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "Deploy the FoodSense backend using Docker Compose. The stack includes the Node.js API server, "
        "PostgreSQL database, and Redis cache.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    story.append(Paragraph("Clone &amp; Configure", styles['SubSection']))
    for e in step_block("1", "Clone the repository",
        "Pull the source code onto the server:"):
        story.append(e)
    story.append(code_block(
        "git clone git@github.com:your-org/foodsense-server.git<br/>"
        "cd foodsense-server"
    ))
    story.append(Spacer(1, 4))

    for e in step_block("2", "Create environment file",
        "Copy the example env file and fill in all required variables:"):
        story.append(e)
    story.append(code_block("cp .env.example .env<br/>nano .env"))
    story.append(Spacer(1, 4))

    # Env vars table
    env_data = [
        [Paragraph('<font color="#FFFFFF"><b>Variable</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Example Value</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Notes</b></font>', styles['TableHeader'])],
        [Paragraph('DATABASE_URL', styles['TableCell']),
         Paragraph('postgresql://user:pass@db:5432/foodsense', styles['TableCell']),
         Paragraph('PostgreSQL connection string', styles['TableCell'])],
        [Paragraph('REDIS_URL', styles['TableCell']),
         Paragraph('redis://redis:6379', styles['TableCell']),
         Paragraph('Redis connection for caching', styles['TableCell'])],
        [Paragraph('GEMINI_API_KEY', styles['TableCell']),
         Paragraph('AIza...', styles['TableCell']),
         Paragraph('Google AI Studio key', styles['TableCell'])],
        [Paragraph('JWT_SECRET', styles['TableCell']),
         Paragraph('(random 64-char string)', styles['TableCell']),
         Paragraph('Auth token signing secret', styles['TableCell'])],
        [Paragraph('FIREBASE_SERVICE_ACCOUNT_PATH', styles['TableCell']),
         Paragraph('./firebase-sa.json', styles['TableCell']),
         Paragraph('Path to service account JSON', styles['TableCell'])],
    ]
    env_table = Table(env_data, colWidths=[140, 160, 140])
    env_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), DARK_GREEN),
        ('BACKGROUND', (0, 1), (-1, -1), LIGHT_GREEN),
        ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('ROUNDEDCORNERS', [6, 6, 6, 6]),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(env_table)
    story.append(Spacer(1, 8))

    for e in step_block("3", "Copy Firebase service account",
        "Download the Firebase service account JSON from Firebase Console &gt; "
        "Project Settings &gt; Service Accounts &gt; Generate New Private Key. "
        "Copy it to the server:"):
        story.append(e)
    story.append(code_block(
        "scp firebase-service-account.json deploy@YOUR_IP:~/foodsense-server/"
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("Launch &amp; Verify", styles['SubSection']))
    for e in step_block("4", "Start all services with Docker Compose",
        "Build and launch the entire stack in detached mode:"):
        story.append(e)
    story.append(code_block("docker compose up -d --build"))
    story.append(Spacer(1, 4))

    for e in step_block("5", "Verify the health check endpoint",
        "Confirm the API is running and responding:"):
        story.append(e)
    story.append(code_block("curl http://localhost:3000/health"))
    story.append(Spacer(1, 4))

    for e in step_block("6", "Run database migrations and seed",
        "Apply the Prisma schema to the database and seed initial data:"):
        story.append(e)
    story.append(code_block(
        "docker compose exec api npx prisma migrate deploy<br/>"
        "docker compose exec api npx prisma db seed"
    ))

    story.append(section_divider())
    story.append(info_box(
        "<b>Warning:</b> Never expose DATABASE_URL or JWT_SECRET publicly. "
        "Use <font face='Courier'>chmod 600 .env</font> to restrict file permissions.",
        LIGHT_AMBER
    ))
    story.append(PageBreak())

    # ========== CHAPTER 4: DOMAIN + SSL ==========
    story.append(colored_box("CHAPTER 4: DOMAIN + SSL CONFIGURATION", BLUE))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "Configure a custom domain with HTTPS so the mobile apps connect securely to the API.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    story.append(Paragraph("DNS Configuration", styles['SubSection']))
    for e in step_block("1", "Add DNS A Record",
        "In your domain registrar's DNS settings, create an <b>A record</b> pointing "
        "your domain (e.g., api.foodsense.app) to your Droplet's public IP address. "
        "TTL can be set to 300 seconds for faster propagation."):
        story.append(e)
    story.append(Spacer(1, 4))

    for e in step_block("2", "Verify DNS propagation",
        "Wait for DNS to propagate (usually 5-30 minutes), then verify:"):
        story.append(e)
    story.append(code_block("dig +short api.foodsense.app"))
    story.append(Spacer(1, 4))

    story.append(Paragraph("Nginx Reverse Proxy", styles['SubSection']))
    for e in step_block("3", "Install Nginx",
        "Install and start the Nginx web server:"):
        story.append(e)
    story.append(code_block("apt install -y nginx<br/>systemctl enable nginx"))
    story.append(Spacer(1, 4))

    for e in step_block("4", "Configure reverse proxy",
        "Create a server block that proxies requests to the Node.js API:"):
        story.append(e)
    story.append(code_block(
        "# /etc/nginx/sites-available/foodsense<br/>"
        "server {<br/>"
        "&nbsp;&nbsp;listen 80;<br/>"
        "&nbsp;&nbsp;server_name api.foodsense.app;<br/><br/>"
        "&nbsp;&nbsp;location / {<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;proxy_pass http://localhost:3000;<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;proxy_http_version 1.1;<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;proxy_set_header Upgrade $http_upgrade;<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;proxy_set_header Connection 'upgrade';<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;proxy_set_header Host $host;<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;proxy_cache_bypass $http_upgrade;<br/>"
        "&nbsp;&nbsp;}<br/>"
        "}"
    ))
    story.append(Spacer(1, 4))

    for e in step_block("5", "Enable the site",
        "Symlink the config and reload Nginx:"):
        story.append(e)
    story.append(code_block(
        "ln -s /etc/nginx/sites-available/foodsense /etc/nginx/sites-enabled/<br/>"
        "nginx -t<br/>"
        "systemctl reload nginx"
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("SSL with Certbot", styles['SubSection']))
    for e in step_block("6", "Install Certbot and obtain SSL certificate",
        "Use Let's Encrypt for free, auto-renewing SSL certificates:"):
        story.append(e)
    story.append(code_block(
        "apt install -y certbot python3-certbot-nginx<br/>"
        "certbot --nginx -d api.foodsense.app"
    ))
    story.append(Spacer(1, 4))

    for e in step_block("7", "Verify auto-renewal",
        "Certbot installs a systemd timer for automatic renewal. Test it:"):
        story.append(e)
    story.append(code_block("certbot renew --dry-run"))

    story.append(section_divider())
    story.append(info_box(
        "<b>Note:</b> SSL certificates from Let's Encrypt expire every 90 days. "
        "The certbot timer renews them automatically. Verify with "
        "<font face='Courier'>systemctl status certbot.timer</font>."
    ))
    story.append(PageBreak())

    # ========== CHAPTER 5: FIREBASE CONFIGURATION ==========
    story.append(colored_box("CHAPTER 5: FIREBASE CONFIGURATION", AMBER))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "Firebase provides authentication, push notifications, and crash reporting "
        "for the FoodSense mobile apps.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    story.append(Paragraph("Authentication Setup", styles['SubSection']))
    for e in step_block("1", "Enable Authentication Providers",
        "In Firebase Console &gt; Authentication &gt; Sign-in method, enable:"):
        story.append(e)
    for e in bullet_list([
        "<b>Email/Password</b> -- Primary sign-in method for registered users.",
        "<b>Anonymous</b> -- Allows users to try the app before creating an account. "
        "Anonymous accounts can be upgraded to permanent accounts later.",
    ]):
        story.append(e)
    story.append(Spacer(1, 4))

    story.append(Paragraph("Cloud Messaging (FCM)", styles['SubSection']))
    for e in step_block("2", "Enable Firebase Cloud Messaging",
        "FCM is enabled by default for new projects. Verify in Firebase Console &gt; "
        "Cloud Messaging. For iOS, upload your APNs authentication key "
        "(from Apple Developer &gt; Keys &gt; Create Key with APNs)."):
        story.append(e)
    story.append(Spacer(1, 4))

    story.append(Paragraph("Download Configuration Files", styles['SubSection']))
    for e in step_block("3", "iOS: Download GoogleService-Info.plist",
        "Firebase Console &gt; Project Settings &gt; Your Apps &gt; iOS app. "
        "Download <b>GoogleService-Info.plist</b> and add it to the Xcode project root."):
        story.append(e)
    story.append(Spacer(1, 4))

    for e in step_block("4", "Android: Download google-services.json",
        "Firebase Console &gt; Project Settings &gt; Your Apps &gt; Android app. "
        "Download <b>google-services.json</b> and place it in <font face='Courier'>android/app/</font>."):
        story.append(e)
    story.append(Spacer(1, 4))

    story.append(Paragraph("Service Account for Server", styles['SubSection']))
    for e in step_block("5", "Generate Service Account JSON",
        "Firebase Console &gt; Project Settings &gt; Service Accounts &gt; "
        "<b>Generate New Private Key</b>. This JSON file is used by the backend server "
        "to verify auth tokens and send push notifications. Keep it secure and never "
        "commit it to version control."):
        story.append(e)

    story.append(section_divider())
    story.append(info_box(
        "<b>Security:</b> Add <font face='Courier'>GoogleService-Info.plist</font>, "
        "<font face='Courier'>google-services.json</font>, and "
        "<font face='Courier'>firebase-service-account.json</font> to your "
        "<font face='Courier'>.gitignore</font>. These files contain project credentials.",
        LIGHT_AMBER
    ))
    story.append(PageBreak())

    # ========== CHAPTER 6: iOS APP STORE SUBMISSION ==========
    story.append(colored_box("CHAPTER 6: iOS APP STORE SUBMISSION", PURPLE))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "Prepare and submit the FoodSense iOS app to the Apple App Store.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    story.append(Paragraph("Xcode Configuration", styles['SubSection']))
    for e in step_block("1", "Open the Xcode workspace",
        "Open <font face='Courier'>FoodSense.xcworkspace</font> (not .xcodeproj) to include "
        "CocoaPods/SPM dependencies."):
        story.append(e)
    for e in step_block("2", "Set Signing &amp; Capabilities",
        "Select the FoodSense target &gt; Signing &amp; Capabilities. Set your <b>Team</b> "
        "(Apple Developer account), <b>Bundle Identifier</b> (e.g., com.yourcompany.foodsense), "
        "and ensure <b>Automatically manage signing</b> is checked."):
        story.append(e)
    for e in step_block("3", "Set version and build number",
        "Under General, set <b>Version</b> (e.g., 1.0.0) and <b>Build</b> (e.g., 1). "
        "Increment the build number for each upload to App Store Connect."):
        story.append(e)
    for e in step_block("4", "Update the API base URL",
        "In the app configuration, update <font face='Courier'>PROXY_BASE_URL</font> to point "
        "to your production server (e.g., https://api.foodsense.app)."):
        story.append(e)
    story.append(Spacer(1, 4))

    story.append(Paragraph("Build &amp; Upload", styles['SubSection']))
    for e in step_block("5", "Create an Archive",
        "Select <b>Product &gt; Archive</b> (ensure a physical device or 'Any iOS Device' "
        "is selected as the build target). Wait for the archive to complete."):
        story.append(e)
    for e in step_block("6", "Upload via Organizer",
        "In the Organizer window, select the archive and click <b>Distribute App</b>. "
        "Choose <b>App Store Connect</b> &gt; <b>Upload</b>. Xcode will validate and upload the build."):
        story.append(e)
    story.append(Spacer(1, 4))

    story.append(Paragraph("App Store Connect", styles['SubSection']))
    for e in step_block("7", "Configure App Store listing",
        "In App Store Connect, fill in the required metadata:"):
        story.append(e)
    for e in bullet_list([
        "<b>App Name:</b> FoodSense",
        "<b>Description &amp; Keywords:</b> Use content from <font face='Courier'>store-assets/</font>",
        "<b>Screenshots:</b> Upload for iPhone 6.7\" and 6.5\" (required). Use the screenshots from store-assets/.",
        "<b>App Icon:</b> 1024x1024 icon (auto-included from the asset catalog)",
        "<b>Privacy Policy URL:</b> Link to your hosted privacy policy page",
        "<b>Pricing:</b> Set to Free (or configure In-App Purchases if applicable)",
    ]):
        story.append(e)
    for e in step_block("8", "Submit for Review",
        "Select the uploaded build, complete all required fields, and click "
        "<b>Submit for Review</b>. Initial review typically takes 24-48 hours."):
        story.append(e)
    story.append(PageBreak())

    # ========== CHAPTER 7: GOOGLE PLAY STORE SUBMISSION ==========
    story.append(colored_box("CHAPTER 7: GOOGLE PLAY STORE SUBMISSION", RED))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "Build and publish the FoodSense Android app to the Google Play Store.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    story.append(Paragraph("Signing Configuration", styles['SubSection']))
    for e in step_block("1", "Generate a release keystore",
        "Create a signing keystore for production builds. Store this file securely -- "
        "losing it means you cannot update the app:"):
        story.append(e)
    story.append(code_block(
        "keytool -genkey -v -keystore foodsense-release.keystore \\<br/>"
        "&nbsp;&nbsp;-alias foodsense -keyalg RSA -keysize 2048 -validity 10000"
    ))
    story.append(Spacer(1, 4))

    for e in step_block("2", "Configure signing in build.gradle",
        "Add the signing configuration to <font face='Courier'>android/app/build.gradle</font>:"):
        story.append(e)
    story.append(code_block(
        "android {<br/>"
        "&nbsp;&nbsp;signingConfigs {<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;release {<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;storeFile file('foodsense-release.keystore')<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;storePassword System.getenv('KEYSTORE_PASSWORD')<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;keyAlias 'foodsense'<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;keyPassword System.getenv('KEY_PASSWORD')<br/>"
        "&nbsp;&nbsp;&nbsp;&nbsp;}<br/>"
        "&nbsp;&nbsp;}<br/>"
        "}"
    ))
    story.append(Spacer(1, 4))

    for e in step_block("3", "Update the API base URL",
        "In the app configuration, update <font face='Courier'>PROXY_BASE_URL</font> to point "
        "to your production server (e.g., https://api.foodsense.app)."):
        story.append(e)
    story.append(Spacer(1, 4))

    story.append(Paragraph("Build Release Bundle", styles['SubSection']))
    for e in step_block("4", "Build Android App Bundle (AAB)",
        "Generate the release AAB file for Play Store upload:"):
        story.append(e)
    story.append(code_block("./gradlew bundleRelease"))
    story.append(Spacer(1, 4))

    story.append(Paragraph(
        "The output AAB will be at "
        "<font face='Courier'>app/build/outputs/bundle/release/app-release.aab</font>.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("Google Play Console", styles['SubSection']))
    for e in step_block("5", "Create app in Play Console",
        "Go to <b>Google Play Console</b> &gt; <b>Create App</b>. Fill in the app name, "
        "default language, app type (Application), and whether it's free or paid."):
        story.append(e)
    for e in step_block("6", "Upload AAB",
        "Navigate to <b>Production</b> &gt; <b>Create new release</b>. Upload the "
        "AAB file. Google Play App Signing is recommended (let Google manage the signing key)."):
        story.append(e)
    for e in step_block("7", "Complete store listing",
        "Fill in all required information:"):
        story.append(e)
    for e in bullet_list([
        "<b>Content Rating:</b> Complete the content rating questionnaire (IARC)",
        "<b>Data Safety:</b> Declare what data the app collects, how it is used, and whether it is shared",
        "<b>Store Listing:</b> Title, short/full description, screenshots, feature graphic from store-assets/",
        "<b>Target Audience:</b> Declare age group and any special categories",
    ]):
        story.append(e)
    for e in step_block("8", "Submit for Review",
        "Once all sections show a green checkmark, click <b>Submit for Review</b>. "
        "Initial review typically takes 1-7 days for new apps."):
        story.append(e)

    story.append(section_divider())
    story.append(info_box(
        "<b>Important:</b> Back up your release keystore and its passwords in a secure location. "
        "If lost, you will need to create a new app listing and lose existing users.",
        LIGHT_RED
    ))
    story.append(PageBreak())

    # ========== CHAPTER 8: MONITORING & MAINTENANCE ==========
    story.append(colored_box("CHAPTER 8: MONITORING &amp; MAINTENANCE", DARK_GREEN))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "Keep the FoodSense backend running smoothly with logging, backups, updates, "
        "and external monitoring.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 8))

    story.append(Paragraph("Logging", styles['SubSection']))
    for e in step_block("1", "View container logs",
        "Monitor real-time logs from all Docker services:"):
        story.append(e)
    story.append(code_block(
        "docker compose logs -f          # all services<br/>"
        "docker compose logs -f api      # API only<br/>"
        "docker compose logs -f db       # database only"
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("Database Backups", styles['SubSection']))
    for e in step_block("2", "Set up automated pg_dump backups",
        "Create a cron job to back up the PostgreSQL database daily:"):
        story.append(e)
    story.append(code_block(
        "# Add to crontab (crontab -e):<br/>"
        "0 3 * * * docker compose exec -T db pg_dump -U postgres foodsense \\<br/>"
        "&nbsp;&nbsp;&gt; /backups/foodsense_$(date +\\%Y\\%m\\%d).sql"
    ))
    story.append(Spacer(1, 4))
    story.append(Paragraph(
        "Consider uploading backups to an offsite location (DigitalOcean Spaces, S3, etc.) "
        "for disaster recovery. Retain at least 7 days of backups.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("Update Procedure", styles['SubSection']))
    for e in step_block("3", "Pull latest code and rebuild",
        "To deploy updates to the server:"):
        story.append(e)
    story.append(code_block(
        "cd ~/foodsense-server<br/>"
        "git pull origin main<br/>"
        "docker compose up -d --build<br/>"
        "docker compose exec api npx prisma migrate deploy"
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("Health Monitoring", styles['SubSection']))
    for e in step_block("4", "Set up UptimeRobot",
        "Create a free account at <b>UptimeRobot.com</b> and add an HTTP(s) monitor "
        "for your health endpoint (https://api.foodsense.app/health). "
        "Configure alerts via email or Slack. Check interval: 5 minutes."):
        story.append(e)
    story.append(Spacer(1, 4))

    story.append(Paragraph("SSL Certificate Renewal", styles['SubSection']))
    for e in step_block("5", "Verify SSL auto-renewal",
        "Let's Encrypt certificates auto-renew via the certbot systemd timer. "
        "Verify the timer is active and test renewal:"):
        story.append(e)
    story.append(code_block(
        "systemctl status certbot.timer<br/>"
        "certbot renew --dry-run"
    ))
    story.append(Spacer(1, 4))

    story.append(Paragraph("Firebase Usage Monitoring", styles['SubSection']))
    for e in step_block("6", "Monitor Firebase quotas",
        "Regularly check Firebase Console &gt; Usage and billing to monitor "
        "Authentication active users, FCM message volume, Crashlytics events, "
        "and Firestore reads/writes. Set up budget alerts to avoid unexpected charges."):
        story.append(e)

    story.append(PageBreak())

    # ========== APPENDIX: ENVIRONMENT VARIABLES ==========
    story.append(colored_box("APPENDIX: ENVIRONMENT VARIABLES REFERENCE", GRAY))
    story.append(Spacer(1, 16))
    story.append(Paragraph(
        "Complete reference of all environment variables used in the FoodSense server "
        "<font face='Courier'>.env</font> file.",
        styles['BodyText2']
    ))
    story.append(Spacer(1, 12))

    appendix_data = [
        [Paragraph('<font color="#FFFFFF"><b>Variable</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Required</b></font>', styles['TableHeader']),
         Paragraph('<font color="#FFFFFF"><b>Description</b></font>', styles['TableHeader'])],
        [Paragraph('<font face="Courier" size="8">DATABASE_URL</font>', styles['TableCell']),
         Paragraph('Yes', styles['TableCellCenter']),
         Paragraph('PostgreSQL connection string. Format: postgresql://user:password@host:port/dbname', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">REDIS_URL</font>', styles['TableCell']),
         Paragraph('Yes', styles['TableCellCenter']),
         Paragraph('Redis connection URL for session cache and rate limiting', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">GEMINI_API_KEY</font>', styles['TableCell']),
         Paragraph('Yes', styles['TableCellCenter']),
         Paragraph('Google AI Studio API key for Gemini model (food detection and AI coach)', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">JWT_SECRET</font>', styles['TableCell']),
         Paragraph('Yes', styles['TableCellCenter']),
         Paragraph('Secret key for signing JWT auth tokens. Use a random 64+ character string', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">FIREBASE_SERVICE<br/>_ACCOUNT_PATH</font>', styles['TableCell']),
         Paragraph('Yes', styles['TableCellCenter']),
         Paragraph('Path to the Firebase service account JSON file for server-side auth and FCM', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">PORT</font>', styles['TableCell']),
         Paragraph('No', styles['TableCellCenter']),
         Paragraph('Server port. Default: 3000', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">NODE_ENV</font>', styles['TableCell']),
         Paragraph('No', styles['TableCellCenter']),
         Paragraph('Environment mode: development or production. Default: development', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">LOG_LEVEL</font>', styles['TableCell']),
         Paragraph('No', styles['TableCellCenter']),
         Paragraph('Logging verbosity: debug, info, warn, error. Default: info', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">RATE_LIMIT_MAX</font>', styles['TableCell']),
         Paragraph('No', styles['TableCellCenter']),
         Paragraph('Maximum API requests per window. Default: 100', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">RATE_LIMIT_WINDOW</font>', styles['TableCell']),
         Paragraph('No', styles['TableCellCenter']),
         Paragraph('Rate limit time window in minutes. Default: 15', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">CORS_ORIGINS</font>', styles['TableCell']),
         Paragraph('No', styles['TableCellCenter']),
         Paragraph('Allowed CORS origins, comma-separated. Default: * (all origins)', styles['TableCell'])],
        [Paragraph('<font face="Courier" size="8">BACKUP_DIR</font>', styles['TableCell']),
         Paragraph('No', styles['TableCellCenter']),
         Paragraph('Directory for automated database backups. Default: /backups', styles['TableCell'])],
    ]
    appendix_table = Table(appendix_data, colWidths=[120, 50, 270])
    appendix_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), DARK_GREEN),
        ('BACKGROUND', (0, 1), (0, -1), LIGHT_GRAY),
        ('BACKGROUND', (1, 1), (-1, -1), white),
        ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
        ('ALIGN', (1, 1), (1, -1), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor("#D1D5DB")),
        ('ROUNDEDCORNERS', [6, 6, 6, 6]),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(appendix_table)

    story.append(Spacer(1, 20))
    story.append(section_divider())
    story.append(Paragraph(
        "FoodSense Deployment &amp; Publishing Guide -- April 2026",
        ParagraphStyle('EndNote', parent=styles['DocSubtitle'], fontSize=10)
    ))

    # Build the PDF
    doc.build(story, onFirstPage=add_page_number, onLaterPages=add_page_number)
    print(f"PDF generated: {OUTPUT_PATH}")


if __name__ == "__main__":
    build_pdf()
