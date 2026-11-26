---
name: trac-doc
description: Vẽ bản vẽ trắc dọc tuyến đường (bảng trắc dọc 8 hàng, đường dóng cọc, đường tự nhiên, đường thiết kế + cong đứng, hàng Đoạn thẳng - Đoạn cong từ file .ntd) trong OpenCADStudio (máy Linux này, qua MCP opencadstudio + script Python tracdoc.py) hoặc AutoCAD qua MCP autocad-mcp (máy Windows) theo layer TK_268_..., text style TK_268_... (font unicode), màu và cỡ chữ theo bản mẫu 02.TNTK.dwg. Dùng khi người dùng yêu cầu vẽ, chỉnh hoặc kiểm tra trắc dọc tuyến.
---

# Skill vẽ trắc dọc (theo bản mẫu `02.TNTK.dwg`)

Nguồn: đọc trực tiếp từ bản vẽ `02.TNTK.dwg` ngày 2026-11-25 (tuyến Km0+0.00 → Km0+480.95, 39 cọc). Tuân theo `CLAUDE.md`: **không tạo layer/style/block mới** (thiếu thì hỏi), không tự lưu, kiểm tra `DWGNAME` trước khi vẽ (bản vẽ active có thể đổi sang file khác; chuyển bằng `vla-activate`).

**Cập nhật 2026-11-25 (theo yêu cầu người dùng):** toàn bộ layer trắc dọc đổi tên thành `TK_268_...`, text style đổi thành `TK_268_...` và dùng font unicode có sẵn trên máy (arial.ttf, calibril.ttf) thay cho `.shx`/VnArial. Chỉ `td:layer` tra theo mã cũ → tên mới; bản vẽ cũ vẫn có layer tên cũ thì hàm tự dùng tên cũ.

Các file lisp (cùng thư mục): `trac-doc-helpers.lsp` (bảng, cọc, đường tự nhiên, ký hiệu km/tỷ lệ, hàng Đoạn thẳng - Đoạn cong, đọc .ntd), `trac-doc-thietke.lsp` (đường thiết kế + cong đứng), `td-khoi-tao.lsp` (lệnh `TDKT`). Đã chạy thử trên `testTDTN.dwg`; lần đầu dùng ở bản vẽ mới vẫn nên thử ở vùng trống, chụp màn hình đối chiếu rồi mới giao.

## 0. Máy Linux này: OpenCADStudio (không có AutoLISP) — DÙNG MỤC NÀY TRƯỚC
OpenCADStudio không chạy được `.lsp`. **Cài đặt (một lần):** `git clone https://github.com/Tuanmetal32/TK_268_trac_doc ~/.claude/skills/trac-doc && cd ~/.claude/skills/trac-doc && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt` (cần Python ≥ 3.9 + MCP opencadstudio). Toàn bộ lisp đã port sang `~/.claude/skills/trac-doc/tracdoc.py` (cùng hình học, layer, màu, style, căn lề; dùng ezdxf trong venv `~/.claude/skills/trac-doc/.venv`).
1. Viết `input.json` (mẫu: `vi-du.json`): `ox, oy, hbase`, `cocs` [(tên, lý trình, CĐ tự nhiên, CĐ thiết kế|null, chỉnh cao|null)] **hoặc** `ntd` (đường dẫn .ntd → lấy cọc + vẽ hàng Đoạn thẳng - Đoạn cong), `ky_hieu` (true), `thiet_ke` {s0,z0,sp,zp,s1,z1,R} nếu có đường đỏ 1 đỉnh + cong đứng.
2. `~/.claude/skills/trac-doc/.venv/bin/python ~/.claude/skills/trac-doc/tracdoc.py input.json out.dxf` (in ra i1, i2, L, T, BVC, EVC để đối chiếu).
3. OCS: `ocs_sessions` → `ocs_open` file DXF (bản vẽ mới, có sẵn 20 layer + 4 style TK_268_) → `ocs_capture` (view `extents` / `region`; ảnh trả về JSON rất dài, dùng ít) → `ocs_save_verified` ra `.dwg` (2018) khi người dùng muốn lưu.
3b. `day_ranh` {i, lech | z0} hoặc nhiều đoạn dốc {lech, doan: [{den: tên cọc | lý trình | null=cuối tuyến, i}, ...]} (hàng Độ dốc đáy rãnh chia theo đoạn, dốc 0 vẽ vạch ngang giữa ô): chèn 2 hàng (chữ màu 4) ngay trên Cao độ tự nhiên, DƯỚI hai hàng thiết kế mặt đường: "Độ dốc đáy rãnh" (66–78), "Cao độ đáy rãnh" (78–90); Dốc dọc TK đẩy lên 90–102, Cao độ TK 102–114; đồ thị dịch lên 24. Chênh cao (CĐ thiết kế mặt đường − CĐ đáy rãnh) ghi TRÊN ĐỒ THỊ, không ở bảng: TEXT cao 1.8 xoay 90°, layer TK_268_DayRanh, bên trái đường dóng 0.3, chân chữ cách đáy rãnh 0.5 tại mỗi cọc — theo yêu cầu người dùng 2026-11-26, đồ thị + ký hiệu phía trên dịch lên 24; đường đáy rãnh layer mới `TK_268_DayRanh` (màu 4, không có trong bản mẫu). Mặc định z0 = cao độ thiết kế (hoặc tự nhiên) đầu tuyến − lech.
4. Chèn vào bản vẽ đang có: chưa làm; hỏi người dùng (có thể dùng INSERT/ATTACH file DXF ở vị trí ox,oy).
Đã chạy thử 2026-11-26 với `SLT_HUNGHOC.ntd` (39 cọc, 349 đối tượng, audit DWG không lỗi). Các mục 4, 4b (lệnh `load`, `TDKT`) bên dưới chỉ áp dụng cho AutoCAD trên Windows (đường dẫn `D:/...`).

## 1. Hệ toạ độ và tỷ lệ
- Đơn vị **mét** (`INSUNITS=6`), vẽ 1:1 trong Model.
- **Ngang 1/1000**: 1 đơn vị = 1 m ngoài thực địa. `X = x0 + lý trình (m)`.
- **Đứng 1/100**: 1 m cao độ = 10 đơn vị. `Y = oy + 120 + 10×(H − Hbase)` (bản mẫu: Hbase = 0, cao độ 0 nằm cao hơn mép trên bảng 30).
- Gốc bảng `(ox, oy)` = góc trái-dưới của bảng. Bản mẫu: ox=401881.894, oy=2313684.888 (toạ độ lớn kiểu UTM). `testTDTN.dwg`: ox=0, oy=0. Khi vẽ mới: hỏi người dùng vị trí đặt, không đè lên nội dung có sẵn.
- Cọc đầu (lý trình 0) tại `x0 = ox + 45.0`. Đầu bảng bên phải = `x0 + L + 2.948`.
- Nhãn tỷ lệ "TLD: 1/100" (xoay 90°) và "TLN: 1/1000" (nằm ngang) đặt bên trái bảng, phía trên.

## 2. Bảng trắc dọc — 8 hàng, cao tổng 90 (đo từ đáy bảng lên)

| # | Hàng (từ dưới lên) | Y đáy → đỉnh | Y chữ tiêu đề |
|---|---|---|---|
| 1 | Đoạn thẳng - Đoạn cong | 0 → 20 | 10 |
| 2 | Lý trình | 20 → 28 | 24 |
| 3 | Tên cọc | 28 → 36 | 32 |
| 4 | Khoảng cách cộng dồn | 36 → 46 | 41 |
| 5 | Khoảng cách lẻ | 46 → 54 | 50 |
| 6 | Cao độ tự nhiên | 54 → 66 | 60 |
| 7 | Dốc dọc thiết kế | 66 → 78 | 72 |
| 8 | Cao độ thiết kế | 78 → 90 | 84 |

Cột tiêu đề rộng 43.1 (đường dọc tại `ox+43.1`); chữ tiêu đề căn giữa tại `ox+21.5`.

## 3. Layer, màu, chữ từng chi tiết

Tên layer chuẩn mới `TK_268_...` (cột 2). Trong lisp luôn gọi `(td:layer "<mã cũ>")` để lấy tên thật, không gõ tay. Tất cả đối tượng **ByLayer**, trừ ô "màu đè".

| Chi tiết | Layer chuẩn (mã cũ) | Màu layer | Màu đè | Chữ |
|---|---|---|---|---|
| Khung + đường kẻ bảng | `TK_268_BangTracDoc` (9302) | 3 | — | TEXT tiêu đề style `TK_268_ChuBang` cao 2.0, wf 0.8, giữa-giữa |
| Khoảng cách cộng dồn, cao độ tự nhiên | `TK_268_ChuTracDoc` (9303) | 3 | 3 | cao 2.0, xoay 90°, căn phải-giữa, cách mép trên hàng 1.0 |
| Cao độ thiết kế | `TK_268_ChuTracDoc` | 3 | **2 (vàng)** | như trên |
| Khoảng cách lẻ | `TK_268_ChuTracDoc` | 3 | 3 | cao 2.0, nằm ngang, giữa-giữa, đặt giữa hai cọc |
| Tên cọc (1, 2, D1…) | `TK_268_ChuTracDoc` | 3 | **5 (xanh dương)** | cao 2.0, nằm ngang, giữa-đáy, cách đáy hàng 1.0 |
| Lý trình Km (Km 0+0.00) | `TK_268_ChuTracDoc` | 3 | **5** | cao 2.0, nằm ngang, giữa-trên |
| Thông số góc/ cong (A = …, R = …) hàng Đoạn thẳng - Đoạn cong | `TK_268_ChuTracDoc` | 3 | **1 (đỏ)** | MTEXT cao 2.0, căn giữa-giữa |
| Giá trị dốc/ đỉnh dốc (vd 331.00) | `TK_268_ChuTracDoc` | 3 | 2 | cao 2.0, nằm ngang |
| Đường dóng cọc | `TK_268_DuongDong` (9305) | 8 | — | — |
| Đường địa hình tự nhiên (LWPOLYLINE) | `TK_268_TracDocTuNhien` (KS-TUY-2401) | 3 | — | — |
| Đường tim/ thiết kế (đỏ) | `TK_268_TimTuyen` (DBO-1101) | 1 | — | lineweight 25 |
| Đường tim hàng Đoạn thẳng - Đoạn cong | `TK_268_DuongTKTimTuyen` (DBO-1601) | 1 | — | LWPOLYLINE + vạch đứng |
| Số chỉnh cao tim tuyến | `TK_268_ChinhCao` (9331) | 2 | — | TEXT cao 2.0, xoay 90°, căn trái-giữa |
| Cọc lý trình/ H/ Km/ cắm cong | `TK_268_CocLyTrinh/CocH/CocKm/CocCamCong` (DBO-1104…1107) | 3 | — | bản mẫu là proxy Civil; hỏi người dùng nếu cần vẽ |
| Điểm đo | `TK_268_DiemDo` (DHI-1101) | 8 | — | — |
| Thông số cong đứng (L=, R=) | `TK_268_ThongSoCong` (9321) | 2 | — | MTEXT style `TK_268_ChuManh` cao 2.0 |
| Ghi chú đầu/ giữa/ cực trị cong đứng | `TK_268_GhiChuDauCong/GiuaCong/CucTri` (9322/9323/9324) | 2 | — | que + mũi tên + TEXT KM/CĐ style `TK_268_ChuManh` cao 1.8 |
| Nhãn "CAO ĐỘ THIẾT KẾ / CAO ĐỘ TỰ NHIÊN" | `TK_268_TextHeader` (TEXTHEADERTD) | 4 | — | style `TK_268_TieuDe` cao 2.0 |
| Nhãn TLD/TLN, khung Km | `TK_268_LyTrinh` (9307) | 3 | 40 (TLD/TLN) | MTEXT style `TK_268_ChuKyHieu` cao 2.0 |
| Thước tỷ lệ | `TK_268_ThuocTL` (9306) | 3 | — | — |
| Điểm chia đoạn | `TK_268_DiemChiaDoan` | 3 | — | — |
| Khung bản vẽ A3 | block `268 A3-cd xref` (scale 1.0 ở layout) | — | — | dùng block có sẵn |

**Text style (font unicode):** `TK_268_ChuBang` = arial.ttf wf 0.8 (bảng, số liệu); `TK_268_ChuKyHieu` = arial.ttf wf 1.0 (Km, tỷ lệ); `TK_268_TieuDe` = arial.ttf; `TK_268_ChuManh` = calibril.ttf (Calibri Light — chữ mảnh cho ghi chú cong đứng).
Layer/ style khác trong template (MSSTracNgang, BIEN BAO, Texttencoc, TENCOC… dành cho bình đồ/ trắc ngang/ biển báo) **không** đổi tên, không dùng cho trắc dọc.

## 4. Quy trình vẽ
1. Xác nhận với người dùng: tuyến nào, **số liệu cọc** (tên cọc, lý trình, cao độ tự nhiên, cao độ thiết kế, chỉnh cao), vị trí đặt `(ox, oy)`, `Hbase`, file `.ntd` nếu có.
2. `DWGNAME` đúng file; `(load ".../trac-doc-helpers.lsp")` rồi `(load ".../trac-doc-thietke.lsp")`.
3. Kiểm tra layer/ style có đủ (`td:layer`, `td:style` báo lỗi nếu thiếu) → thiếu thì **dừng, hỏi**; nếu người dùng đồng ý thì chạy `TDKT` (mục 4b).
4. `(td:ve ox oy L Hbase cocs)` với `cocs = '(("1" 0.0 1.45 nil nil) ("D1" 9.17 1.34 nil nil) ...)` = (tên, lý trình, cao độ tự nhiên, cao độ thiết kế hoặc nil, chỉnh cao hoặc nil).
5. Ký hiệu Km đầu/ cuối + tỷ lệ: `(td:ky-hieu ox oy L)`.
6. Hàng Đoạn thẳng - Đoạn cong: mục 4d.
7. `zoom` vào bảng, chụp màn hình, đối chiếu bản mẫu; báo rõ phần **chưa kiểm tra** và **chưa lưu**. (Lưu ý: `ssget "W"/"C"` chỉ chọn được đối tượng đang nằm trong khung nhìn; dùng `ssget "X"` có lọc layer khi kiểm đếm.)

## 4b. Nạp nhanh layer + text style vào bản vẽ mới
`(load "D:/01. JOB/01. Mr. Tuan/Other/Training/Claude/.claude/skills/trac-doc/td-khoi-tao.lsp")` rồi gõ **`TDKT`**: tạo 20 layer `TK_268_...` và 4 text style (`TK_268_ChuKyHieu`, `TK_268_TieuDe`, `TK_268_ChuBang`, `TK_268_ChuManh`). Chỉ tạo phần còn thiếu, không sửa/ xóa cái đã có. Chỉ chạy khi người dùng đồng ý (CLAUDE.md B1). Font arial.ttf, calibril.ttf có sẵn trên Windows.

## 4c. Phần thiết kế (đường đỏ + cong đứng) — `trac-doc-thietke.lsp`
- `(td:tk-thong-so s0 z0 spvi zpvi s1 z1 R)`: 1 đỉnh đổi dốc (PVI) + cong đứng parabol bán kính R; trả `(i1 i2 Lc T sb se)`. Công thức: `i1=(zp−z0)/(sp−s0)`, `i2=(z1−zp)/(s1−sp)`, `L=R·|i1−i2|`, `T=L/2`, BVC=sp−T, EVC=sp+T. Ví dụ `testTDTN`: R=3000, i1=0.2734 %, i2=−0.0181 %, L=8.746, BVC 145.582, EVC 154.328, cao độ PVI 1.86.
- `(td:thiet-ke ox oy hbase cocs)`: vẽ hàng cao độ thiết kế (vàng) + số chỉnh cao, đường thiết kế đỏ (đoạn thẳng + parabol bước 0.5 m), hàng dốc dọc (đường chéo + `%` + chiều dài đoạn), ghi chú cong đứng. Phải gọi `td:tk-thong-so` trước. **Không vẽ** hàng Đoạn thẳng - Đoạn cong (do `td:doan-cong`).
- `td:cong-dung`: tiếp tuyến BVC–PVI–EVC, vòng tròn BVC/EVC (+ cực trị nếu có), tam giác PVI, ngoặc + que, MTEXT `R = …, Di = 0.00` / `L = …, Lvc = …` (style `TK_268_ChuManh`).
- `td:nhan-lttd2 x y cd km layer side`: nhãn mũi tên + chữ "CĐ: …" / "KM0 + …" xoay 90°, TEXT cao 1.8, style `TK_268_ChuManh` (Calibri Light). `side` 0 = giữa (như block LTTD), −1 = chữ nằm bên trái que, 1 = chữ bên phải que (BVC dùng −1, EVC dùng 1 với CĐ cách que 2.9 m, PVI dùng 0) — tránh đè chữ khi cong ngắn.

## 4d. Hàng "Đoạn thẳng - Đoạn cong" từ file .ntd — `trac-doc-helpers.lsp`
- `(td:doc-ntd "C:/.../SLT_HUNGHOC.ntd")` → danh sách `(tên lý-trình cao-độ R góc-rad)` từ các dòng `POLE`. Góc = π là đoạn thẳng; khác π là đỉnh góc (D1, D3…); bộ `TDn / Pn / TCn` là đường cong nằm (P có R ở cột 6 = đường cong, TD/TC là đầu/ cuối).
- `(td:doan-cong ox oy L poles)` (hình dạng đo lại trên bản mẫu 02.TNTK, 2026-11-25): một LWPOLYLINE đỏ (layer `TK_268_DuongTKTimTuyen`) chạy ngang ở **`oy+10`**; tại mỗi đỉnh góc thường: góc âm → hình "mái nhà" **lồi lên** rộng 12 (±6) cao 6, chữ ở dưới đường (tâm `oy+8`); góc dương → hình chữ V **lõm xuống** rộng 12 sâu 6, chữ ở trên đường (tâm `oy+12`); đường cong tròn (P có R): đường đỏ đổi thành hình chữ nhật hở đáy rộng K (từ TD đến TC) cao 4 (lên nếu góc âm, xuống nếu dương), chữ 3 dòng tâm tại giữa TD–TC, `oy+8`/`oy+12` theo dấu góc. MTEXT đỏ (layer `TK_268_ChuTracDoc`, cao 2.0, **căn giữa-giữa** attachment 5): `A = D°M'S.SS''` (góc lấy ra `>180°` thì âm: `−(360−góc)`), riêng đường cong thêm `R = …` / `D = … P = …` / `K = … T = …` (T=R·tan(φ/2), K=R·φ, P=R(1/cos(φ/2)−1), D=2T−K, φ=π−|A|; đã kiểm khớp bản mẫu: R=5, T=4.87, K=7.72, P=1.98, D=2.02). Điểm cuối tuyến ghi `A = ` để trống như bản mẫu.
- Kích thước hình (12×6, K×4) đo từ ảnh bản mẫu (proxy Civil không đọc được số liệu) nên sai số nhỏ; góc dương + đường cong chưa có mẫu thật để đối chiếu (suy theo đối xứng).
- Đã chạy thử trên `testTDTN.dwg`: 1 polyline + 8 MTEXT cho `SLT_HUNGHOC.ntd` (xóa bản cũ sai trước khi vẽ lại).

## 5. Lưu ý
- Bản vẽ đích trống: chỉ khi người dùng **đồng ý** mới chạy `TDKT` hoặc `(td:tao-layer-style)` (4 layer cơ bản + `TK_268_ChuBang`) / `(td:tao-layer-style-ky-hieu)` (`TK_268_LyTrinh` + `TK_268_ChuKyHieu`).
- Khung Km: chữ giữa-giữa cao 2.0, khung chữ nhật rộng ≈ 15.25 (9 ký tự) × cao 6.0, que dài 1.9 xuống, đặt tại x cọc, cao cố định oy+155.9…163.8 (bản mẫu là proxy Civil nên kích thước ước lượng từ ảnh). Tam giác tỷ lệ: 3 điểm (27.629,124.335) (27.629,105.042) (14.646,105.042) so với gốc bảng, layer `TK_268_BangTracDoc`; TLD xoay 90° tại (29.158,106.662), TLN tại (13.833,103.834).
- `td:ve` nhận cọc có `cao độ thiết kế = nil` thì bỏ qua toàn bộ phần thiết kế. Đã dùng cho `SLT_HUNGHOC.ntd` → `testTDTN.dwg` (2026-11-25), sau đó thêm thiết kế (R=3000) và hàng Đoạn thẳng - Đoạn cong.
- File số liệu `.ntd`: dòng `POLE` = tên cọc, lý trình, cao độ tự nhiên, a, R, góc (rad); các dòng `TARGETL/R` là trắc ngang (chưa dùng).
- Layer của trắc ngang (`TK-ADS-94xx`, chữ cao 0.4/0.6) khác trắc dọc — không trộn.
- Bản mẫu có nhiều đối tượng proxy Civil (không đọc/ vẽ lại được bằng entmake): thay bằng đối tượng thường trên cùng layer và ghi rõ trong báo cáo.
- Số liệu đo ở bản mẫu lấy từ ba cọc đầu (0.00, 9.17, 22.46); công thức nhất quán với toàn tuyến nhưng chưa kiểm hết 39 cọc.
- Khi trộn nhiều lần `td:ve`/`td:thiet-ke` trên cùng bản vẽ sẽ nhân đôi đối tượng — chỉ vẽ một lần mỗi hạng mục, hoặc xóa đối tượng của mình trước (lọc theo layer + vùng toạ độ).
