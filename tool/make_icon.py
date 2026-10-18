# 生成 eCAT 粉色猫爪 App 图标源图（1024x1024 PNG）
# 设计：奶油白圆角底 + 樱花粉猫爪印（一大四小肉垫），可爱风
from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# ---- 背景：奶油白圆角方块（Android 自适应会裁圆，Windows 用方形圆角）----
CREAM = (255, 251, 245, 255)      # AppColors.cream
PINK = (248, 165, 184, 255)       # AppColors.pink
PINK_DEEP = (232, 116, 143, 255)  # AppColors.pinkDeep
PINK_LIGHT = (253, 232, 238, 255) # AppColors.pinkLight

d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=220, fill=CREAM)

# ---- 猫爪印：中央大肉垫 + 上方四趾 ----
cx, cy = SIZE // 2, SIZE // 2 + 90  # 爪印中心略偏下

def ellipse(box, fill):
    d.ellipse(box, fill=fill)

# 大肉垫：圆润倒三角感 —— 用三个交叠椭圆拼成
pad_w, pad_h = 300, 240
ellipse([cx - pad_w // 2, cy - pad_h // 2, cx + pad_w // 2, cy + pad_h // 2], PINK)
ellipse([cx - pad_w // 2 + 40, cy - 10, cx + pad_w // 2 - 40, cy + pad_h // 2 + 60], PINK)

# 四个脚趾：左外/左内/右内/右外，中间两趾略高
toe_r = 78
toes = [
    (cx - 250, cy - 150, toe_r),        # 左外
    (cx - 95,  cy - 265, toe_r + 6),    # 左内（略高略大）
    (cx + 95,  cy - 265, toe_r + 6),    # 右内
    (cx + 250, cy - 150, toe_r),        # 右外
]
for tx, ty, r in toes:
    ellipse([tx - r, ty - r, tx + r, ty + r], PINK)

# ---- 点缀：右上角小爪印（浅粉，增加层次）----
sx, sy, s = 800, 200, 0.32
small_pad = int(300 * s)
ellipse([sx - small_pad // 2, sy - int(120 * s), sx + small_pad // 2, sy + int(120 * s)], PINK_LIGHT)
for tx, ty in [(-250, -150), (-95, -265), (95, -265), (250, -150)]:
    r = int(80 * s)
    tx2, ty2 = sx + int(tx * s), sy + int(ty * s)
    ellipse([tx2 - r, ty2 - r, tx2 + r, ty2 + r], PINK_LIGHT)

# ---- 点缀：左下角两颗小心心 ----
def heart(x, y, size, fill):
    d.ellipse([x - size, y - size, x, y], fill=fill)
    d.ellipse([x, y - size, x + size, y], fill=fill)
    d.polygon([(x - size, y - size // 2), (x + size, y - size // 2), (x, y + size)], fill=fill)

heart(190, 760, 42, PINK_LIGHT)
heart(262, 830, 26, PINK_LIGHT)

img.save("assets/icon/icon_source.png")
print("OK: assets/icon/icon_source.png", img.size)
