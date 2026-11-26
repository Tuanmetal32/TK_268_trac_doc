#!/usr/bin/env python3
"""tracdoc.py - ve trac doc ra file DXF (ban port Python cua trac-doc-helpers.lsp + trac-doc-thietke.lsp
+ td-khoi-tao.lsp) de mo/ chen trong OpenCADStudio (khong co AutoLISP).

Cach dung:
    ~/.claude/skills/trac-doc/.venv/bin/python ~/.claude/skills/trac-doc/tracdoc.py input.json output.dxf

input.json (xem vi-du.json):
{
  "ox": 0, "oy": 0, "L": 480.95, "hbase": 0,
  "cocs": [["1", 0.0, 1.45, null, null], ["D1", 9.17, 1.34, null, null], ...],
        # (ten, ly trinh, cao do tu nhien, cao do thiet ke|null, chinh cao|null)
  "ky_hieu": true,                       # Km dau/cuoi + ky hieu ty le (td:ky-hieu)
  "ntd": "duong/dan/file.ntd",           # tuy chon: hang Doan thang - Doan cong (td:doan-cong)
  "thiet_ke": {"s0":0,"z0":1.45,"sp":150,"zp":1.86,"s1":480.95,"z1":1.80,"R":3000}
                                         # tuy chon: duong do + cong dung (td:tk-thong-so + td:thiet-ke)
  "day_ranh": {"i": -0.003, "lech": 0.5}  # tuy chon: day ranh doc deu (i<0 = doc xuong ve cuoi);
        # hoac nhieu doan: {"lech": 0.5, "doan": [{"den": "15", "i": 0}, {"den": null, "i": -0.002}]}
                                         # z0 = cao do dau (neu bo trong = mat duong dau tuyen - lech)
}
Neu khong co "L" thi lay ly trinh coc cuoi; neu khong co "cocs" ma co "ntd" thi lay coc tu .ntd.
"""
import json
import math
import sys

import ezdxf
from ezdxf.enums import TextEntityAlignment

PI = math.pi

# ---- Layer + text style chuan (td-khoi-tao.lsp) ----
LAYERS = [
    ("TK_268_DiemChiaDoan", 3), ("TK_268_TimTuyen", 1), ("TK_268_DuongTKTimTuyen", 1),
    ("TK_268_CocLyTrinh", 3), ("TK_268_CocH", 3), ("TK_268_CocKm", 3), ("TK_268_CocCamCong", 3),
    ("TK_268_DiemDo", 8), ("TK_268_ChuTracDoc", 3), ("TK_268_ThuocTL", 3), ("TK_268_LyTrinh", 3),
    ("TK_268_DuongDong", 8), ("TK_268_TracDocTuNhien", 3), ("TK_268_BangTracDoc", 3),
    ("TK_268_ChinhCao", 2), ("TK_268_ThongSoCong", 2), ("TK_268_GhiChuDauCong", 2),
    ("TK_268_GhiChuCucTri", 2), ("TK_268_GhiChuGiuaCong", 2), ("TK_268_TextHeader", 4), ("TK_268_DayRanh", 4),
]
STYLES = [  # ten, width factor, font
    ("TK_268_ChuKyHieu", 1.0, "arial.ttf"), ("TK_268_TieuDe", 1.0, "arial.ttf"),
    ("TK_268_ChuBang", 0.8, "arial.ttf"), ("TK_268_ChuManh", 1.0, "calibril.ttf"),
]
L_BANG, L_CHU, L_DONG, L_TN = "TK_268_BangTracDoc", "TK_268_ChuTracDoc", "TK_268_DuongDong", "TK_268_TracDocTuNhien"
L_LT, L_CC, L_TIM, L_DTK = "TK_268_LyTrinh", "TK_268_ChinhCao", "TK_268_TimTuyen", "TK_268_DuongTKTimTuyen"
L21, L22, L23, L24 = "TK_268_ThongSoCong", "TK_268_GhiChuDauCong", "TK_268_GhiChuGiuaCong", "TK_268_GhiChuCucTri"
ST_BANG, ST_KH, ST_MANH = "TK_268_ChuBang", "TK_268_ChuKyHieu", "TK_268_ChuManh"

ROWS = [  # ten, y day, y dinh, y chu
    ("Đoạn thẳng - Đoạn cong", 0.0, 20.0, 10.0), ("Lý trình", 20.0, 28.0, 24.0),
    ("Tên cọc", 28.0, 36.0, 32.0), ("Khoảng cách cộng dồn", 36.0, 46.0, 41.0),
    ("Khoảng cách lẻ", 46.0, 54.0, 50.0), ("Cao độ tự nhiên", 54.0, 66.0, 60.0),
    ("Dốc dọc thiết kế", 66.0, 78.0, 72.0), ("Cao độ thiết kế", 78.0, 90.0, 84.0),
]

# khi co day ranh: 2 hang nay chen vao 66-90 (duoi 2 hang thiet ke mat duong, 2 hang do day len 90-114)
ROWS_RANH = [("Độ dốc đáy rãnh", 66.0, 78.0, 72.0), ("Cao độ đáy rãnh", 78.0, 90.0, 84.0)]
DR = 24.0  # chieu cao 2 hang day ranh
L_RANH = "TK_268_DayRanh"  # layer moi (mau 4) cho duong day ranh - khong co trong ban mau 02.TNTK

# (hj, vj) DXF 72/73 -> ezdxf alignment
ALIGN = {
    (1, 2): TextEntityAlignment.MIDDLE_CENTER, (4, 2): TextEntityAlignment.MIDDLE_CENTER,
    (1, 1): TextEntityAlignment.BOTTOM_CENTER, (1, 3): TextEntityAlignment.TOP_CENTER,
    (2, 2): TextEntityAlignment.MIDDLE_RIGHT, (0, 1): TextEntityAlignment.BOTTOM_LEFT,
    (0, 3): TextEntityAlignment.TOP_LEFT, (0, 2): TextEntityAlignment.MIDDLE_LEFT,
}


def r2(v):
    return f"{v:.2f}"


class TD:
    def __init__(self, ox, oy, hbase=0.0):
        self.doc = ezdxf.new("R2018", setup=False)
        self.doc.header["$INSUNITS"] = 6
        self.doc.header["$DWGCODEPAGE"] = "ANSI_1258"
        for name, color in LAYERS:
            self.doc.layers.add(name, color=color, linetype="Continuous")
        for name, wf, font in STYLES:
            self.doc.styles.add(name, font=font).dxf.width = wf
        self.msp = self.doc.modelspace()
        self.ox, self.oy, self.hbase = ox, oy, hbase
        self.x0 = ox + 45.0
        self.ranh = False
        self.dk = 0.0  # dich 2 hang thiet ke mat duong (DR khi co day ranh)
        self.ya = oy  # goc phan tren bang (dich len DR khi co hang day ranh)

    def bat_ranh(self):
        """Chen 2 hang 'Do doc day ranh' (66-78), 'Cao do day ranh' (78-90) duoi 2 hang thiet ke mat duong (doi len 90-114); do thi dich len DR."""
        self.ranh = True
        self.dk = DR
        self.ya = self.oy + DR

    def y(self, H):  # cao do -> Y (TLD 1/100 = x10)
        return self.ya + 120.0 + 10.0 * (H - self.hbase)

    # --- primitive ---
    def text(self, s, x, y, h, rot_rad, hj, vj, layer, color=None, style=ST_BANG):
        attr = {"layer": layer, "style": style, "height": h, "width": 0.8,
                "rotation": math.degrees(rot_rad)}
        if color is not None:
            attr["color"] = color
        t = self.msp.add_text(s, dxfattribs=attr)
        t.set_placement((x, y), align=ALIGN[(hj, vj)])
        return t

    def line(self, x1, y1, x2, y2, layer):
        self.msp.add_line((x1, y1), (x2, y2), dxfattribs={"layer": layer})

    def pline(self, pts, layer, closed=False, lw=None):
        attr = {"layer": layer}
        if lw is not None:
            attr["lineweight"] = lw
        self.msp.add_lwpolyline(pts, close=closed, dxfattribs=attr)

    def circle(self, x, y, r, layer):
        self.msp.add_circle((x, y), r, dxfattribs={"layer": layer})

    def mtext(self, s, x, y, layer, style, attach=5, color=None, width=0.0, direction=(1, 0, 0)):
        attr = {"layer": layer, "style": style, "char_height": 2.0, "attachment_point": attach,
                "insert": (x, y), "text_direction": direction}
        if width:
            attr["width"] = width
        if color is not None:
            attr["color"] = color
        self.msp.add_mtext(s, dxfattribs=attr)

    # --- td:khung ---
    def khung(self, L):
        ox, oy = self.ox, self.oy
        xr = ox + 45.0 + L + 2.948
        rows = (ROWS[:6] + ROWS_RANH + [(r[0], r[1] + DR, r[2] + DR, r[3] + DR) for r in ROWS[6:]]) if self.ranh else ROWS
        top = 90.0 + (DR if self.ranh else 0.0)
        for r in rows:
            self.line(ox, oy + r[1], xr, oy + r[1], L_BANG)
        self.line(ox, oy + top, xr, oy + top, L_BANG)
        self.line(ox, oy, ox, oy + top, L_BANG)
        self.line(ox + 43.1, oy, ox + 43.1, oy + top, L_BANG)
        self.line(xr, oy, xr, oy + top, L_BANG)
        for r in rows:
            self.text(r[0], ox + 21.5, oy + r[3], 2.0, 0.0, 4, 2, L_BANG)

    # --- td:ve ---
    def ve(self, L, cocs):
        oy, x0 = self.oy, self.x0
        self.khung(L)
        prev, nat = None, []
        for i, c in enumerate(cocs):
            ten, s, ztn = c[0], c[1], c[2]
            ztk = c[3] if len(c) > 3 else None
            cc = c[4] if len(c) > 4 else None
            x, yg = x0 + s, self.y(ztn)
            self.line(x, self.ya + 90.0, x, yg, L_DONG)
            self.text(r2(s), x, oy + 45.0, 2.0, PI / 2, 2, 2, L_CHU, 3)
            self.text(r2(ztn), x, oy + 65.0, 2.0, PI / 2, 2, 2, L_CHU, 3)
            if ten[:1].isdigit():
                self.text(ten, x, oy + 29.0, 2.0, 0.0, 1, 1, L_CHU, 5)
            else:
                nxt = cocs[i + 1] if i + 1 < len(cocs) else None
                if (prev and s - prev[1] < 6.0) or (nxt and nxt[1] - s < 6.0):
                    self.text(ten, x, oy + 35.0, 2.0, PI / 2, 2, 2, L_CHU, 5)
                else:
                    self.text(ten, x, oy + 35.0, 2.0, 0.0, 1, 3, L_CHU, 5)
            if prev:
                d = s - prev[1]
                self.text(r2(d), (x + x0 + prev[1]) / 2.0, oy + 50.0, 2.0,
                          PI / 2 if d < 6.0 else 0.0, 1, 2, L_CHU, 3)
            if ztk is not None:
                yd = self.y(ztk)
                self.text(r2(ztk), x, oy + self.dk + 89.0, 2.0, PI / 2, 2, 2, L_CHU, 2)
                if cc is not None:
                    self.text(r2(cc), x - 1.0, yd + 2.0, 2.0, PI / 2, 0, 1, L_CC)
            nat.append((x, yg))
            prev = c
        self.text("Km 0+0.00", x0 + 5.567, oy + 26.4, 2.0, 0.0, 1, 3, L_CHU, 5)
        self.text("Km 0+" + r2(L), x0 + L - 5.567, oy + 26.4, 2.0, 0.0, 1, 3, L_CHU, 5)
        self.pline(nat, L_TN)
        if all(len(c) > 3 and c[3] is not None for c in cocs):
            self.pline([(x0 + c[1], self.y(c[3])) for c in cocs], L_TIM)

    # --- td:ky-hieu ---
    def km(self, s, x):
        oy = self.oy
        w = max(15.25, 15.25 * len(s) / 9.0)
        self.pline([(x - w / 2, self.ya + 157.8), (x + w / 2, self.ya + 157.8), (x + w / 2, self.ya + 163.8),
                    (x - w / 2, self.ya + 163.8)], L_LT, closed=True)
        self.line(x, self.ya + 155.9, x, self.ya + 157.8, L_LT)
        self.text(s, x, self.ya + 160.8, 2.0, 0.0, 1, 2, L_LT)

    def ty_le(self):
        ox, oy = self.ox, self.oy
        self.pline([(ox + 27.629, self.ya + 124.335), (ox + 27.629, self.ya + 105.042), (ox + 14.646, self.ya + 105.042)],
                   L_BANG, closed=True)
        self.mtext("TLD: 1/100", ox + 29.158, self.ya + 106.662, L_LT, ST_KH, attach=1, color=40,
                   width=14.362, direction=(0, 1, 0))
        self.mtext("TLN: 1/1000", ox + 13.833, self.ya + 103.834, L_LT, ST_KH, attach=1, color=40)

    def ky_hieu(self, L):
        self.km("Km 0+0.00", self.x0)
        self.km("Km 0+" + r2(L), self.x0 + L)
        self.ty_le()

    # --- td:doan-cong ---
    @staticmethod
    def fmt_goc(ang):
        d = math.degrees(ang)
        if d > 180.0:
            d -= 360.0
        ad = abs(d)
        dg = int(ad)
        mn = int((ad - dg) * 60.0)
        sc = (ad - dg - mn / 60.0) * 3600.0
        return f"{'-' if d < 0 else ''}{dg}°{mn}'{sc:.2f}''"

    def doan_cong(self, L, poles):
        oy, x0 = self.oy, self.x0
        yb, hw = oy + 10.0, 6.0
        vs = [(x0, yb)]

        def mt(s, x, y):
            self.mtext(s, x, y, L_CHU, ST_BANG, attach=5, color=1)

        n = len(poles)
        for i, p in enumerate(poles):
            ang, x = p[4], x0 + p[1]
            if abs(ang - PI) <= 1e-6:
                continue
            neg = ang > PI
            if p[3] > 0.0 and 0 < i < n - 1:
                pn, pp1 = poles[i - 1], poles[i + 1]
                sb, se, rr = x0 + pn[1], x0 + pp1[1], p[3]
                phi = PI - abs(2 * PI - ang if neg else ang)
                tg = rr * math.tan(phi / 2)
                kk = rr * phi
                pk = rr * (1 / math.cos(phi / 2) - 1)
                dd = 2 * tg - kk
                h = 4.0 if neg else -4.0
                vs += [(sb, yb), (sb, yb + h), (se, yb + h), (se, yb)]
                mt(f"A = {self.fmt_goc(ang)} R = {r2(rr)}\\PD = {r2(dd)} P = {r2(pk)}\\PK = {r2(kk)} T = {r2(tg)}",
                   (sb + se) / 2, oy + 8.0 if neg else oy + 12.0)
            else:
                vs += [(x - hw, yb), (x, yb + (6.0 if neg else -6.0)), (x + hw, yb)]
                mt(f"A = {self.fmt_goc(ang)}", x, oy + 8.0 if neg else oy + 12.0)
        mt("A = ", x0 + L, oy + 12.0)
        vs.append((x0 + L, yb))
        self.pline(vs, L_DTK)

    # --- td:tk-thong-so + td:thiet-ke + td:cong-dung ---
    def tk_thong_so(self, s0, z0, sp, zp, s1, z1, R):
        self.s0, self.z0, self.sp, self.zp, self.s1, self.z1, self.R = s0, z0, sp, zp, s1, z1, R
        self.i1 = (zp - z0) / (sp - s0)
        self.i2 = (z1 - zp) / (s1 - sp)
        self.Lc = R * abs(self.i1 - self.i2)
        self.T = self.Lc / 2
        self.sb, self.se = sp - self.T, sp + self.T
        self.zb = z0 + self.i1 * (self.sb - s0)
        return self.i1, self.i2, self.Lc, self.T, self.sb, self.se

    def ze(self, s):
        if s <= self.sb:
            return self.z0 + self.i1 * (s - self.s0)
        if s >= self.se:
            return self.zp + self.i2 * (s - self.sp)
        x = s - self.sb
        return self.zb + self.i1 * x + (self.i2 - self.i1) * x * x / (2 * self.Lc)

    def thiet_ke(self, cocs):
        oy, x0 = self.oy, self.x0
        for c in cocs:
            x, z = x0 + c[1], self.ze(c[1])
            g = z - c[2]
            self.text(r2(z), x, oy + self.dk + 89.0, 2.0, PI / 2, 2, 2, L_CHU, 2)
            self.text(r2(g), x - 1.0, self.y(z) + (2.0 if g > 0.005 else 0.0), 2.0, PI / 2, 0, 1, L_CC)
        pts = [(x0 + self.s0, self.y(self.z0))]
        s = self.sb
        while s < self.se:
            pts.append((x0 + s, self.y(self.ze(s))))
            s += 0.5
        pts.append((x0 + self.se, self.y(self.ze(self.se))))
        pts.append((x0 + self.s1, self.y(self.z1)))
        self.pline(pts, L_TIM, lw=25)
        yb, yt = oy + self.dk + 66.0, oy + self.dk + 78.0
        for sx in (self.s0, self.sp, self.s1):
            self.line(x0 + sx, yb, x0 + sx, yt, L_CHU)
        for a, b, i in ((self.s0, self.sp, self.i1), (self.sp, self.s1, self.i2)):
            xs, xe = x0 + a, x0 + b
            ym = (xs + xe) / 2
            if i > 0:
                self.line(xs, yb, xe, yt, L_CHU)
            else:
                self.line(xs, yt, xe, yb, L_CHU)
            self.text(r2(100 * abs(i)) + "%", ym, oy + self.dk + 72.2, 2.0, 0.0, 1, 1, L_CHU, 2)
            self.text(r2(b - a), ym, oy + self.dk + 71.8, 2.0, 0.0, 1, 3, L_CHU, 2)
        self.cong_dung()

    def nhan_lttd2(self, x, y, cd, km, layer, side):
        if side == -1:
            xk, xc = x - 5.2, x - 0.5
        elif side == 1:
            xk, xc = x + 4.2, x + 2.9
        else:
            xk, xc = x + 0.4695, x - 0.1139
        self.line(x, y, x, y + 18.0, layer)
        self.line(x, y, x + 0.54, y + 1.8, layer)
        self.line(x, y, x - 0.54, y + 1.8, layer)
        self.text(km, xk, y + 3.2586, 1.8, PI / 2, 0, 3, layer, style=ST_MANH)
        self.text(cd, xc, y + 3.2586, 1.8, PI / 2, 0, 1, layer, style=ST_MANH)

    def cong_dung(self):
        oy, x0 = self.oy, self.x0
        xb, xe, xp = x0 + self.sb, x0 + self.se, x0 + self.sp
        yb, ye, yp = self.y(self.zb), self.y(self.ze(self.se)), self.y(self.zp)
        self.line(xb, yb, xp, yp, L21)
        self.line(xe, ye, xp, yp, L21)
        self.circle(xb, yb, 1.0, L22)
        self.circle(xe, ye, 1.0, L22)
        xx = self.i1 * self.R
        if 0 < xx < self.Lc:
            self.circle(xb + xx, self.y(self.ze(self.sb + xx)), 1.0, L24)
        self.line(xp, yp + 1, xp - 1, yp - 1, L23)
        self.line(xp, yp + 1, xp + 1, yp - 1, L23)
        self.line(xp - 1, yp - 1, xp + 1, yp - 1, L23)
        self.pline([(xb, self.ya + 156.6), (xb, self.ya + 158.6), (xe, self.ya + 158.6), (xe, self.ya + 156.6)], L21)
        self.line(xp, self.ya + 158.6, xp, self.ya + 154.6, L21)
        self.mtext(f"R = {r2(self.R)}, Di = 0.00", xp, self.ya + 165.6, L21, ST_MANH)
        self.mtext(f"L = {r2(self.Lc)}, Lvc = {r2(self.Lc)}", xp, self.ya + 168.6, L21, ST_MANH)
        y = self.ya + 170.6
        self.nhan_lttd2(xb, y, "CĐ: " + r2(self.ze(self.sb)), "KM0 + " + r2(self.sb), L22, -1)
        self.nhan_lttd2(xe, y, "CĐ: " + r2(self.ze(self.se)), "KM0 + " + r2(self.se), L22, 1)
        self.nhan_lttd2(xp, y, "CĐ: " + r2(self.zp), "KM0 + " + r2(self.sp), L23, 0)

    # --- day ranh: 1 doan doc deu tu dau den cuoi ---
    def day_ranh(self, cocs, z0, segs, L, zmd=None):
        """Day ranh nhieu doan doc: segs = [(s_cuoi_doan, i), ...] (doan cuoi den L).
        zmd(s): cao do thiet ke mat duong -> ghi chenh cao (mat duong - day ranh) TREN do thi, ngay tren duong day ranh tai moi coc."""
        oy, x0 = self.oy, self.x0
        bps = [(0.0, z0)]  # diem doi doc (ly trinh, cao do)
        for se, i in segs:
            s0, zz = bps[-1]
            bps.append((se, zz + i * (se - s0)))

        def zr(s):
            for (sa, za), (sb, zb) in zip(bps, bps[1:]):
                if s <= sb + 1e-9:
                    return za + (zb - za) * (s - sa) / (sb - sa)
            return bps[-1][1]
        self.pline([(x0 + sa, self.y(za)) for sa, za in bps], L_RANH)
        for c in cocs:
            self.text(r2(zr(c[1])), x0 + c[1], oy + 89.0, 2.0, PI / 2, 2, 2, L_CHU, 4)
            if zmd is not None:  # chu xoay 90, ben trai duong dong, chan chu cach day ranh 0.5
                self.text(r2(zmd(c[1]) - zr(c[1])), x0 + c[1] - 0.3, self.y(zr(c[1])) + 0.5, 1.8, PI / 2, 0, 1, L_RANH)
        yb, yt = oy + 66.0, oy + 78.0
        for sa, _ in bps:
            self.line(x0 + sa, yb, x0 + sa, yt, L_CHU)
        for ((sa, za), (sb, zb)), (_, i) in zip(zip(bps, bps[1:]), segs):
            xa, xb = x0 + sa, x0 + sb
            if abs(i) < 1e-12:
                self.line(xa, (yb + yt) / 2, xb, (yb + yt) / 2, L_CHU)
            elif i > 0:
                self.line(xa, yb, xb, yt, L_CHU)
            else:
                self.line(xa, yt, xb, yb, L_CHU)
            ym = (xa + xb) / 2
            self.text(r2(100 * abs(i)) + "%", ym, oy + 72.2, 2.0, 0.0, 1, 1, L_CHU, 4)
            self.text(r2(sb - sa), ym, oy + 71.8, 2.0, 0.0, 1, 3, L_CHU, 4)
        return bps


def doc_ntd(path):
    """Dong POLE: ten, ly trinh, cao do, a, R, goc(rad) -> (ten, s, z, R, goc)."""
    out = []
    with open(path, encoding="utf-8", errors="replace") as f:
        for ln in f:
            tk = ln.rstrip("\r\n").split("\t")
            if tk[0] == "POLE" and len(tk) > 6:
                out.append((tk[1], float(tk[2]), float(tk[3]), float(tk[5]), float(tk[6])))
    return out


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    cfg = json.load(open(sys.argv[1], encoding="utf-8"))
    poles = doc_ntd(cfg["ntd"]) if cfg.get("ntd") else None
    cocs = cfg.get("cocs") or [[p[0], p[1], p[2], None, None] for p in (poles or [])]
    if not cocs:
        sys.exit("Thieu so lieu coc (cocs hoac ntd)")
    L = cfg.get("L") or cocs[-1][1]
    td = TD(cfg.get("ox", 0.0), cfg.get("oy", 0.0), cfg.get("hbase", 0.0))
    tk = cfg.get("thiet_ke")
    dr = cfg.get("day_ranh")
    if dr:
        td.bat_ranh()
    td.ve(L, [c[:3] + [None, None] if tk else c for c in cocs])
    if cfg.get("ky_hieu", True):
        td.ky_hieu(L)
    if poles:
        td.doan_cong(L, poles)
    if tk:
        r = td.tk_thong_so(tk["s0"], tk["z0"], tk["sp"], tk["zp"], tk["s1"], tk["z1"], tk["R"])
        print("i1=%.4f%% i2=%.4f%% L=%.3f T=%.3f BVC=%.3f EVC=%.3f" % (r[0] * 100, r[1] * 100, *r[2:]))
        td.thiet_ke(cocs)
    if dr:
        z0 = dr.get("z0")
        if z0 is None:  # thap hon mat duong (thiet ke, neu khong co thi tu nhien) tai dau tuyen 'lech' m
            z0 = (td.ze(cocs[0][1]) if tk else cocs[0][2]) - dr.get("lech", 0.5)
        zmd = td.ze if tk else ({c[1]: c[3] for c in cocs}.get if all(len(c) > 3 and c[3] is not None for c in cocs) else None)
        ten = {c[0]: c[1] for c in cocs}
        if "doan" in dr:  # [{"den": ten coc | ly trinh | null(=cuoi tuyen), "i": doc}, ...]
            segs = [(L if d.get("den") is None else (ten[d["den"]] if isinstance(d["den"], str) else d["den"]), d["i"]) for d in dr["doan"]]
        else:
            segs = [(L, dr["i"])]
        bps = td.day_ranh(cocs, z0, segs, L, zmd)
        print("Day ranh: " + " | ".join("%.3f@%.2f" % (z, s) for s, z in bps))
    td.doc.saveas(sys.argv[2], encoding="utf-8")
    print(f"Da ghi {sys.argv[2]}: {len(td.msp)} doi tuong, {len(cocs)} coc, L={L}")


if __name__ == "__main__":
    main()
