"""
Generate App Store screenshots for DataPost iOS app.
Creates screenshots showing the app in use for both iPhone and iPad.

Required sizes:
- iPhone 6.7": 1290x2796
- iPad 13":    2048x2732

Usage: python generate_screenshots.py
"""

from PIL import Image, ImageDraw, ImageFont
import os
import sys

SCREENSHOTS_DIR = os.path.join(os.path.dirname(__file__), "screenshots")
os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

# --- Colors ---
BG_COLOR = (242, 242, 247)       # iOS light gray background
CARD_BG = (255, 255, 255)        # White cards
BLUE = (0, 122, 255)             # iOS blue
GREEN = (52, 199, 89)            # iOS green
ORANGE = (255, 149, 0)           # iOS orange
RED = (255, 59, 48)              # iOS red
PURPLE = (175, 82, 222)          # iOS purple
YELLOW = (255, 204, 0)           # iOS yellow
TEXT_PRIMARY = (0, 0, 0)
TEXT_SECONDARY = (142, 142, 147)
NAV_BG = (249, 249, 249)
TAB_BG = (249, 249, 249)
SEPARATOR = (200, 200, 200)
FORM_BG = (242, 242, 247)
FORM_ROW_BG = (255, 255, 255)
BLUE_LIGHT = (0, 122, 255, 25)
GREEN_LIGHT = (52, 199, 89, 25)
ORANGE_LIGHT = (255, 149, 0, 25)
PURPLE_LIGHT = (175, 82, 222, 25)


def get_font(size, bold=False):
    """Try to load a system font, fallback to default."""
    font_paths = [
        # Windows
        "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/segoeuib.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/arialbd.ttf",
        # macOS
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFPro.ttf",
    ]
    if bold:
        bold_paths = [
            "C:/Windows/Fonts/segoeuib.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
        ]
        for p in bold_paths:
            if os.path.exists(p):
                try:
                    return ImageFont.truetype(p, size)
                except Exception:
                    pass
    for p in font_paths:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                pass
    return ImageFont.load_default()


def rounded_rect(draw, xy, radius, fill, outline=None):
    """Draw a rounded rectangle."""
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline)


def draw_status_bar(draw, w, scale):
    """Draw iOS status bar."""
    y = int(12 * scale)
    font = get_font(int(14 * scale), bold=True)
    draw.text((int(32 * scale), y), "9:41", fill=TEXT_PRIMARY, font=font)
    # Battery icon (simplified)
    bx = w - int(40 * scale)
    by = y + int(2 * scale)
    bw = int(25 * scale)
    bh = int(12 * scale)
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=int(2 * scale), outline=TEXT_PRIMARY, width=max(1, int(1.5 * scale)))
    draw.rectangle([bx + int(2 * scale), by + int(2 * scale), bx + bw - int(2 * scale), by + bh - int(2 * scale)], fill=GREEN)


def draw_nav_bar(draw, w, scale, title, y_start):
    """Draw navigation bar with title. Returns y after nav bar."""
    nav_h = int(44 * scale)
    # Nav background
    draw.rectangle([0, y_start, w, y_start + nav_h], fill=NAV_BG)
    font = get_font(int(17 * scale), bold=True)
    bbox = draw.textbbox((0, 0), title, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((w - tw) // 2, y_start + int(12 * scale)), title, fill=TEXT_PRIMARY, font=font)
    return y_start + nav_h


def draw_large_title(draw, w, scale, title, y_start):
    """Draw large title. Returns y after title."""
    font = get_font(int(34 * scale), bold=True)
    draw.text((int(20 * scale), y_start + int(8 * scale)), title, fill=TEXT_PRIMARY, font=font)
    return y_start + int(52 * scale)


def draw_tab_bar(draw, w, h, scale, active_tab=0):
    """Draw tab bar at bottom."""
    tab_h = int(83 * scale)
    y = h - tab_h
    draw.rectangle([0, y, w, h], fill=TAB_BG)
    draw.line([0, y, w, y], fill=SEPARATOR, width=max(1, int(0.5 * scale)))

    tabs = [
        ("Status", "↻"),
        ("Profile", "👤"),
        ("Settings", "⚙"),
    ]
    tab_w = w // len(tabs)
    font = get_font(int(10 * scale))
    icon_font = get_font(int(22 * scale))

    for i, (label, icon) in enumerate(tabs):
        cx = tab_w * i + tab_w // 2
        color = BLUE if i == active_tab else TEXT_SECONDARY

        # Icon circle
        circle_r = int(12 * scale)
        circle_y = y + int(10 * scale)
        draw.ellipse([cx - circle_r, circle_y, cx + circle_r, circle_y + circle_r * 2], fill=color)

        # Label
        bbox = draw.textbbox((0, 0), label, font=font)
        lw = bbox[2] - bbox[0]
        draw.text((cx - lw // 2, y + int(42 * scale)), label, fill=color, font=font)


def draw_connection_card(draw, w, scale, y, connected=False):
    """Draw the connection status card. Returns y after card."""
    card_h = int(80 * scale)
    mx = int(16 * scale)
    rounded_rect(draw, [mx, y, w - mx, y + card_h], int(12 * scale), fill=CARD_BG)

    # WiFi icon
    icon_x = mx + int(16 * scale)
    icon_y = y + int(20 * scale)
    icon_r = int(18 * scale)
    draw.ellipse([icon_x, icon_y, icon_x + icon_r * 2, icon_y + icon_r * 2],
                 fill=GREEN if connected else TEXT_SECONDARY)

    # Text
    tx = icon_x + icon_r * 2 + int(16 * scale)
    font_title = get_font(int(17 * scale), bold=True)
    font_sub = get_font(int(13 * scale))
    status_text = "Connected to RACHEL" if connected else "Not Connected"
    sub_text = "RACHEL-Demo" if connected else "Connect to a RACHEL WiFi network"
    draw.text((tx, y + int(18 * scale)), status_text, fill=TEXT_PRIMARY, font=font_title)
    draw.text((tx, y + int(42 * scale)), sub_text, fill=TEXT_SECONDARY, font=font_sub)

    return y + card_h + int(16 * scale)


def draw_transfer_card(draw, w, scale, y, label, icon_color, count, is_active=False, progress=0.0):
    """Draw a transfer status card. Returns y after card."""
    card_h = int(70 * scale)
    mx = int(16 * scale)
    rounded_rect(draw, [mx, y, w - mx, y + card_h], int(8 * scale), fill=CARD_BG)

    # Icon
    ix = mx + int(14 * scale)
    iy = y + int(16 * scale)
    ir = int(16 * scale)
    draw.ellipse([ix, iy, ix + ir * 2, iy + ir * 2], fill=icon_color)

    # Text
    tx = ix + ir * 2 + int(14 * scale)
    font_title = get_font(int(15 * scale))
    font_sub = get_font(int(12 * scale))
    draw.text((tx, y + int(12 * scale)), label, fill=TEXT_PRIMARY, font=font_title)

    if is_active:
        # Progress bar
        bar_y = y + int(38 * scale)
        bar_w = w - mx * 2 - (tx - mx) - int(14 * scale)
        bar_h = int(6 * scale)
        rounded_rect(draw, [tx, bar_y, tx + bar_w, bar_y + bar_h], int(3 * scale), fill=(230, 230, 230))
        if progress > 0:
            rounded_rect(draw, [tx, bar_y, tx + int(bar_w * progress), bar_y + bar_h], int(3 * scale), fill=icon_color)
        draw.text((tx, bar_y + int(10 * scale)), "Syncing content...", fill=TEXT_SECONDARY, font=font_sub)
    else:
        draw.text((tx, y + int(36 * scale)), f"{count} files pending", fill=TEXT_SECONDARY, font=font_sub)

    return y + card_h + int(10 * scale)


def draw_action_buttons(draw, w, scale, y):
    """Draw action buttons. Returns y after buttons."""
    mx = int(16 * scale)
    btn_h = int(50 * scale)

    # View Bundles button
    rounded_rect(draw, [mx, y, w - mx, y + btn_h], int(10 * scale), fill=BLUE)
    font = get_font(int(16 * scale), bold=True)
    text = "View Bundles"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((w - tw) // 2, y + int(14 * scale)), text, fill=(255, 255, 255), font=font)
    y += btn_h + int(10 * scale)

    # Sync Now and Scan buttons side by side
    half = (w - mx * 2 - int(10 * scale)) // 2
    rounded_rect(draw, [mx, y, mx + half, y + btn_h], int(10 * scale), fill=GREEN)
    text = "Sync Now"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((mx + (half - tw) // 2, y + int(14 * scale)), text, fill=(255, 255, 255), font=font)

    x2 = mx + half + int(10 * scale)
    rounded_rect(draw, [x2, y, x2 + half, y + btn_h], int(10 * scale), fill=ORANGE)
    text = "Scan"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text((x2 + (half - tw) // 2, y + int(14 * scale)), text, fill=(255, 255, 255), font=font)

    return y + btn_h + int(16 * scale)


def generate_status_screen(w, h, scale):
    """Generate Status tab screenshot."""
    img = Image.new('RGB', (w, h), BG_COLOR)
    draw = ImageDraw.Draw(img)

    draw_status_bar(draw, w, scale)
    safe_top = int(59 * scale)
    y = draw_nav_bar(draw, w, scale, "", safe_top)
    y = draw_large_title(draw, w, scale, "Status", y)
    y += int(8 * scale)

    y = draw_connection_card(draw, w, scale, y, connected=True)

    # Section header
    font_head = get_font(int(15 * scale), bold=True)
    draw.text((int(20 * scale), y), "Transfer Status", fill=TEXT_PRIMARY, font=font_head)
    y += int(28 * scale)

    y = draw_transfer_card(draw, w, scale, y, "Downloads", BLUE, 3, is_active=True, progress=0.65)
    y = draw_transfer_card(draw, w, scale, y, "Uploads", GREEN, 1)

    # Push buttons toward bottom
    btn_y = h - int(83 * scale) - int(140 * scale)
    draw_action_buttons(draw, w, scale, btn_y)

    draw_tab_bar(draw, w, h, scale, active_tab=0)
    return img


def generate_profile_screen(w, h, scale):
    """Generate Profile tab screenshot."""
    img = Image.new('RGB', (w, h), BG_COLOR)
    draw = ImageDraw.Draw(img)

    draw_status_bar(draw, w, scale)
    safe_top = int(59 * scale)
    y = draw_nav_bar(draw, w, scale, "", safe_top)
    y = draw_large_title(draw, w, scale, "Profile", y)
    y += int(12 * scale)

    mx = int(16 * scale)

    # Avatar circle
    avatar_r = int(40 * scale)
    cx = w // 2
    draw.ellipse([cx - avatar_r, y, cx + avatar_r, y + avatar_r * 2], fill=(0, 122, 255, 50))
    # Initials
    init_font = get_font(int(32 * scale), bold=True)
    bbox = draw.textbbox((0, 0), "JD", font=init_font)
    iw = bbox[2] - bbox[0]
    ih = bbox[3] - bbox[1]
    draw.text((cx - iw // 2, y + avatar_r - ih // 2), "JD", fill=BLUE, font=init_font)
    y += avatar_r * 2 + int(10 * scale)

    # Name & email
    name_font = get_font(int(22 * scale), bold=True)
    email_font = get_font(int(14 * scale))
    bbox = draw.textbbox((0, 0), "Jeremy Demo", font=name_font)
    draw.text((cx - (bbox[2] - bbox[0]) // 2, y), "Jeremy Demo", fill=TEXT_PRIMARY, font=name_font)
    y += int(30 * scale)
    bbox = draw.textbbox((0, 0), "jeremy@worldpossible.org", font=email_font)
    draw.text((cx - (bbox[2] - bbox[0]) // 2, y), "jeremy@worldpossible.org", fill=TEXT_SECONDARY, font=email_font)
    y += int(24 * scale)

    # Verified badge
    badge_font = get_font(int(12 * scale))
    badge_text = "✓ Verified Courier"
    bbox = draw.textbbox((0, 0), badge_text, font=badge_font)
    bw = bbox[2] - bbox[0] + int(20 * scale)
    bh = int(26 * scale)
    bx = cx - bw // 2
    rounded_rect(draw, [bx, y, bx + bw, y + bh], int(13 * scale), fill=(52, 199, 89, 25))
    draw.text((bx + int(10 * scale), y + int(5 * scale)), badge_text, fill=GREEN, font=badge_font)
    y += bh + int(24 * scale)

    # "Your Impact" header
    impact_font = get_font(int(17 * scale), bold=True)
    draw.text((mx, y), "Your Impact", fill=TEXT_PRIMARY, font=impact_font)
    y += int(30 * scale)

    # Stats cards - 3 columns
    stats = [
        ("12", "RACHELs\nVisited", BLUE),
        ("48", "Deliveries", GREEN),
        ("31", "Pickups", ORANGE),
    ]
    card_w = (w - mx * 2 - int(20 * scale)) // 3
    card_h = int(110 * scale)
    val_font = get_font(int(28 * scale), bold=True)
    label_font = get_font(int(11 * scale))

    for i, (val, label, color) in enumerate(stats):
        x = mx + i * (card_w + int(10 * scale))
        # Card with color tint
        r, g, b = color
        light = (r, g, b, 25)
        rounded_rect(draw, [x, y, x + card_w, y + card_h], int(12 * scale), fill=(min(255, r + 200), min(255, g + 200), min(255, b + 200)))

        # Circle icon area
        icon_y = y + int(12 * scale)
        ir = int(14 * scale)
        draw.ellipse([x + card_w // 2 - ir, icon_y, x + card_w // 2 + ir, icon_y + ir * 2], fill=color)

        # Value
        bbox = draw.textbbox((0, 0), val, font=val_font)
        vw = bbox[2] - bbox[0]
        draw.text((x + (card_w - vw) // 2, y + int(46 * scale)), val, fill=TEXT_PRIMARY, font=val_font)

        # Label - center each line
        for j, line in enumerate(label.split('\n')):
            bbox = draw.textbbox((0, 0), line, font=label_font)
            lw = bbox[2] - bbox[0]
            draw.text((x + (card_w - lw) // 2, y + int(80 * scale) + j * int(14 * scale)), line, fill=TEXT_SECONDARY, font=label_font)

    y += card_h + int(20 * scale)

    # Community ranking
    rank_font = get_font(int(17 * scale), bold=True)
    draw.text((mx, y), "Community Ranking", fill=TEXT_PRIMARY, font=rank_font)
    y += int(30 * scale)

    # Two rank cards
    rank_data = [
        ("#3", "of 156", "Devices Rank"),
        ("#7", "of 156", "Deliveries Rank"),
    ]
    rcard_w = (w - mx * 2 - int(10 * scale)) // 2
    rcard_h = int(100 * scale)

    for i, (rank, of_total, title) in enumerate(rank_data):
        x = mx + i * (rcard_w + int(10 * scale))
        rounded_rect(draw, [x, y, x + rcard_w, y + rcard_h], int(12 * scale), fill=CARD_BG)

        # Medal icon
        medal_r = int(12 * scale)
        draw.ellipse([x + rcard_w // 2 - medal_r, y + int(10 * scale),
                       x + rcard_w // 2 + medal_r, y + int(10 * scale) + medal_r * 2], fill=YELLOW)

        bbox = draw.textbbox((0, 0), rank, font=val_font)
        rw = bbox[2] - bbox[0]
        draw.text((x + (rcard_w - rw) // 2, y + int(38 * scale)), rank, fill=TEXT_PRIMARY, font=val_font)

        bbox = draw.textbbox((0, 0), of_total, font=label_font)
        draw.text((x + (rcard_w - (bbox[2] - bbox[0])) // 2, y + int(66 * scale)), of_total, fill=TEXT_SECONDARY, font=label_font)

        bbox = draw.textbbox((0, 0), title, font=label_font)
        draw.text((x + (rcard_w - (bbox[2] - bbox[0])) // 2, y + int(82 * scale)), title, fill=TEXT_SECONDARY, font=label_font)

    y += rcard_h + int(16 * scale)

    # Community bar
    comm_h = int(44 * scale)
    rounded_rect(draw, [mx, y, w - mx, y + comm_h], int(10 * scale), fill=(min(255, 175 + 200), min(255, 82 + 170), min(255, 222 + 30)))
    comm_font = get_font(int(12 * scale))
    draw.text((mx + int(14 * scale), y + int(14 * scale)), "👥  Part of 156 active couriers worldwide", fill=PURPLE, font=comm_font)

    draw_tab_bar(draw, w, h, scale, active_tab=1)
    return img


def draw_form_row(draw, w, scale, y, label, value=None, is_toggle=False, toggle_on=True, is_destructive=False, icon_name=None):
    """Draw a settings form row. Returns y after row."""
    mx = int(16 * scale)
    row_h = int(44 * scale)
    draw.rectangle([mx, y, w - mx, y + row_h], fill=FORM_ROW_BG)
    draw.line([mx + int(16 * scale), y + row_h, w - mx, y + row_h], fill=SEPARATOR, width=1)

    font = get_font(int(16 * scale))
    text_color = RED if is_destructive else TEXT_PRIMARY
    draw.text((mx + int(16 * scale), y + int(12 * scale)), label, fill=text_color, font=font)

    if is_toggle:
        # Toggle switch
        tx = w - mx - int(51 * scale)
        ty = y + int(8 * scale)
        tw, th = int(51 * scale), int(31 * scale)
        bg_color = GREEN if toggle_on else (229, 229, 234)
        rounded_rect(draw, [tx, ty, tx + tw, ty + th], int(15 * scale), fill=bg_color)
        # Knob
        knob_r = int(13 * scale)
        kx = tx + tw - knob_r - int(2 * scale) if toggle_on else tx + int(2 * scale)
        draw.ellipse([kx, ty + int(2 * scale), kx + knob_r * 2, ty + int(2 * scale) + knob_r * 2], fill=(255, 255, 255))
    elif value:
        val_font = get_font(int(15 * scale))
        bbox = draw.textbbox((0, 0), value, font=val_font)
        draw.text((w - mx - int(16 * scale) - (bbox[2] - bbox[0]), y + int(13 * scale)), value, fill=TEXT_SECONDARY, font=val_font)

    return y + row_h


def draw_form_section_header(draw, w, scale, y, title):
    """Draw a form section header. Returns y after header."""
    font = get_font(int(13 * scale))
    draw.text((int(32 * scale), y + int(8 * scale)), title.upper(), fill=TEXT_SECONDARY, font=font)
    return y + int(32 * scale)


def generate_settings_screen(w, h, scale):
    """Generate Settings tab screenshot."""
    img = Image.new('RGB', (w, h), FORM_BG)
    draw = ImageDraw.Draw(img)

    draw_status_bar(draw, w, scale)
    safe_top = int(59 * scale)
    y = draw_nav_bar(draw, w, scale, "", safe_top)
    y = draw_large_title(draw, w, scale, "Settings", y)
    y += int(4 * scale)

    mx = int(16 * scale)

    # Sync Settings section
    y = draw_form_section_header(draw, w, scale, y, "Sync Settings")
    # Top rounded corners
    rounded_rect(draw, [mx, y, w - mx, y + int(4 * scale)], int(10 * scale), fill=FORM_ROW_BG)
    y = draw_form_row(draw, w, scale, y, "Auto-Sync", is_toggle=True, toggle_on=True)
    y = draw_form_row(draw, w, scale, y, "Sync on WiFi Only", is_toggle=True, toggle_on=True)
    y = draw_form_row(draw, w, scale, y, "Upload Quality", value="Original")
    y += int(8 * scale)

    # Notifications section
    y = draw_form_section_header(draw, w, scale, y, "Notifications")
    y = draw_form_row(draw, w, scale, y, "Push Notifications", is_toggle=True, toggle_on=True)
    y += int(8 * scale)

    # Storage section
    y = draw_form_section_header(draw, w, scale, y, "Storage")
    y = draw_form_row(draw, w, scale, y, "Downloaded Bundles", value="2.4 GB")
    y = draw_form_row(draw, w, scale, y, "Pending Uploads", value="156 MB")
    y = draw_form_row(draw, w, scale, y, "Clear Local Data", is_destructive=True)
    y += int(8 * scale)

    # About section
    y = draw_form_section_header(draw, w, scale, y, "About")
    y = draw_form_row(draw, w, scale, y, "Version", value="1.1 (3)")
    y = draw_form_row(draw, w, scale, y, "World Possible Website")
    y = draw_form_row(draw, w, scale, y, "Privacy Policy")
    y = draw_form_row(draw, w, scale, y, "Support")
    y += int(8 * scale)

    # Account section
    y = draw_form_section_header(draw, w, scale, y, "Account")
    y = draw_form_row(draw, w, scale, y, "Sign Out", is_destructive=True)
    y = draw_form_row(draw, w, scale, y, "Delete Account", is_destructive=True)

    # Footer
    footer_font = get_font(int(12 * scale))
    draw.text((int(32 * scale), y + int(8 * scale)), "Signed in as jeremy@worldpossible.org", fill=TEXT_SECONDARY, font=footer_font)

    draw_tab_bar(draw, w, h, scale, active_tab=2)
    return img


def generate_bundles_screen(w, h, scale):
    """Generate Bundle list screenshot."""
    img = Image.new('RGB', (w, h), BG_COLOR)
    draw = ImageDraw.Draw(img)

    draw_status_bar(draw, w, scale)
    safe_top = int(59 * scale)

    # Nav bar with Close button and title
    nav_h = int(44 * scale)
    draw.rectangle([0, safe_top, w, safe_top + nav_h], fill=NAV_BG)
    nav_font = get_font(int(17 * scale), bold=True)
    title = "Content Bundles"
    bbox = draw.textbbox((0, 0), title, font=nav_font)
    tw = bbox[2] - bbox[0]
    draw.text(((w - tw) // 2, safe_top + int(12 * scale)), title, fill=TEXT_PRIMARY, font=nav_font)
    close_font = get_font(int(17 * scale))
    draw.text((int(16 * scale), safe_top + int(12 * scale)), "Close", fill=BLUE, font=close_font)
    y = safe_top + nav_h

    # Search bar
    search_y = y + int(8 * scale)
    search_h = int(36 * scale)
    mx = int(16 * scale)
    rounded_rect(draw, [mx, search_y, w - mx, search_y + search_h], int(10 * scale), fill=(229, 229, 234))
    search_font = get_font(int(15 * scale))
    draw.text((mx + int(32 * scale), search_y + int(8 * scale)), "Search bundles", fill=TEXT_SECONDARY, font=search_font)
    y = search_y + search_h + int(12 * scale)

    # Section header
    header_font = get_font(int(13 * scale))
    draw.text((mx + int(4 * scale), y), "5 BUNDLES AVAILABLE", fill=TEXT_SECONDARY, font=header_font)
    y += int(24 * scale)

    # Bundle rows
    bundles = [
        ("Wikipedia for Schools", "Educational articles from Wikipedia", "Encyclopedia", "5.5 GB", True, BLUE),
        ("Khan Academy Lite", "Math and science video lessons", "Education", "3.2 GB", True, GREEN),
        ("OpenStax Textbooks", "Free college textbooks", "Textbooks", "1.8 GB", False, ORANGE),
        ("MedLine Medical", "Medical reference materials", "Health", "800 MB", True, RED),
        ("CK-12 Flexbooks", "Interactive textbooks for K-12", "Education", "2.1 GB", False, GREEN),
    ]

    title_font = get_font(int(16 * scale), bold=True)
    desc_font = get_font(int(12 * scale))
    cat_font = get_font(int(10 * scale))
    size_font = get_font(int(12 * scale))
    row_h = int(80 * scale)

    for title_text, desc, category, size, downloaded, color in bundles:
        # Row background
        draw.rectangle([0, y, w, y + row_h], fill=CARD_BG)
        draw.line([mx, y + row_h, w, y + row_h], fill=SEPARATOR, width=1)

        # Icon square
        icon_size = int(50 * scale)
        icon_x = mx
        icon_y = y + (row_h - icon_size) // 2
        r, g, b = color
        rounded_rect(draw, [icon_x, icon_y, icon_x + icon_size, icon_y + icon_size], int(8 * scale),
                      fill=(min(255, r + 180), min(255, g + 180), min(255, b + 180)))
        # Small colored circle in icon
        cr = int(10 * scale)
        draw.ellipse([icon_x + icon_size // 2 - cr, icon_y + icon_size // 2 - cr,
                       icon_x + icon_size // 2 + cr, icon_y + icon_size // 2 + cr], fill=color)

        # Text
        tx = icon_x + icon_size + int(12 * scale)
        draw.text((tx, y + int(12 * scale)), title_text, fill=TEXT_PRIMARY, font=title_font)
        draw.text((tx, y + int(32 * scale)), desc, fill=TEXT_SECONDARY, font=desc_font)

        # Category badge + size
        bbox = draw.textbbox((0, 0), category, font=cat_font)
        badge_w = bbox[2] - bbox[0] + int(10 * scale)
        badge_h = int(18 * scale)
        badge_y = y + int(50 * scale)
        rounded_rect(draw, [tx, badge_y, tx + badge_w, badge_y + badge_h], int(4 * scale), fill=(229, 229, 234))
        draw.text((tx + int(5 * scale), badge_y + int(3 * scale)), category, fill=TEXT_PRIMARY, font=cat_font)
        draw.text((tx + badge_w + int(8 * scale), badge_y + int(3 * scale)), size, fill=TEXT_SECONDARY, font=size_font)

        # Download status icon
        check_r = int(15 * scale)
        check_x = w - mx - check_r * 2
        check_y = y + (row_h - check_r * 2) // 2
        if downloaded:
            draw.ellipse([check_x, check_y, check_x + check_r * 2, check_y + check_r * 2], fill=GREEN)
        else:
            draw.ellipse([check_x, check_y, check_x + check_r * 2, check_y + check_r * 2], outline=BLUE, width=int(2 * scale))

        y += row_h

    return img


def main():
    # Device sizes: (width, height, scale_factor, prefix)
    devices = [
        (1290, 2796, 3.0, "iphone"),    # iPhone 6.7"
        (2048, 2732, 2.0, "ipad"),       # iPad 13"
    ]

    screens = [
        ("status", generate_status_screen),
        ("profile", generate_profile_screen),
        ("settings", generate_settings_screen),
        ("bundles", generate_bundles_screen),
    ]

    for w, h, base_scale, prefix in devices:
        scale = base_scale
        for name, generator in screens:
            print(f"Generating {prefix}_{name} ({w}x{h})...")
            img = generator(w, h, scale)
            path = os.path.join(SCREENSHOTS_DIR, f"{prefix}_{name}.png")
            img.save(path, "PNG")
            print(f"  Saved: {path}")

    print(f"\nAll screenshots saved to: {SCREENSHOTS_DIR}")
    print("\nUpload to App Store Connect:")
    print("  iPhone 6.7\" display: iphone_*.png")
    print("  iPad 13\" display:    ipad_*.png")


if __name__ == "__main__":
    main()
