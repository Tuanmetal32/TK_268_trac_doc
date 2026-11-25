;;; trac-doc-helpers.lsp - ve trac doc theo ban mau 02.TNTK.dwg (don vi m, TLD 1/100, TLN 1/1000)
;;; QUY TAC: KHONG tao layer/style moi. Ten layer/style duoc tim theo ma, thieu thi bao loi va dung.
;;; Cach dung:  (load "...trac-doc-helpers.lsp")  roi  xem ham (td:ve ...) cuoi file.

(defun td:err (msg) (princ (strcat "\n[TRAC DOC] " msg)) nil)

;; Bang ma layer (ma cu cua ban mau 02.TNTK) -> ten layer chuan TK_268_ (doi ten 2026-11-25)
(setq td:*ln*
  '(("TK-ADS-9302-" . "TK_268_BangTracDoc")    ("TK-ADS-9303-" . "TK_268_ChuTracDoc")
    ("TK-ADS-9305-" . "TK_268_DuongDong")      ("KS-TUY-2401-" . "TK_268_TracDocTuNhien")
    ("TK-ADS-9306-" . "TK_268_ThuocTL")        ("TK-ADS-9307-" . "TK_268_LyTrinh")
    ("TK-ADS-9331-" . "TK_268_ChinhCao")       ("TK-ADS-9321-" . "TK_268_ThongSoCong")
    ("TK-ADS-9322-" . "TK_268_GhiChuDauCong")  ("TK-ADS-9323-" . "TK_268_GhiChuGiuaCong")
    ("TK-ADS-9324-" . "TK_268_GhiChuCucTri")   ("TK-DBO-1101-" . "TK_268_TimTuyen")
    ("TK-DBO-1601-" . "TK_268_DuongTKTimTuyen") ("TK-DBO-1104-" . "TK_268_CocLyTrinh")
    ("TK-DBO-1105-" . "TK_268_CocH")           ("TK-DBO-1106-" . "TK_268_CocKm")
    ("TK-DBO-1107-" . "TK_268_CocCamCong")     ("KS-DHI-1101-" . "TK_268_DiemDo")
    ("DIEM_CHIA_DOAN" . "TK_268_DiemChiaDoan") ("TEXTHEADERTD" . "TK_268_TextHeader")))

;; Tim ten layer that trong ban ve theo ma (vd "TK-ADS-9303-"): uu tien ten TK_268_ moi, neu khong co thi
;; tim theo tien to ma cu (ban ve cu/ 02.TNTK); khong tao moi
(defun td:layer (key / n l r)
  (setq n (cdr (assoc key td:*ln*)))
  (if (and n (tblsearch "LAYER" n))
    n
    (progn
      (setq l (tblnext "LAYER" T) r nil)
      (while (and l (not r))
        (if (wcmatch (strcase (cdr (assoc 2 l))) (strcat (strcase key) "*"))
          (setq r (cdr (assoc 2 l))))
        (setq l (tblnext "LAYER")))
      (if (not r) (td:err (strcat "Thieu layer " key " (" (if n n "") ") -> hoi nguoi dung")))
      r)))

;; Text style chuan: TK_268_ChuBang (arial.ttf, wf 0.8); neu ban ve cu thi tim "ADS-Bang trac doc"
(defun td:style (/ l r)
  (if (tblsearch "STYLE" "TK_268_ChuBang")
    "TK_268_ChuBang"
    (progn
      (setq l (tblnext "STYLE" T) r nil)
      (while (and l (not r))
        (if (wcmatch (strcase (cdr (assoc 2 l))) "ADS-B*NG TR*C D*C")
          (setq r (cdr (assoc 2 l))))
        (setq l (tblnext "STYLE")))
      (if (not r) (td:err "Thieu text style TK_268_ChuBang -> hoi nguoi dung (hoac go TDKT)"))
      r)))
;; Style chu manh (calibril.ttf) cho ghi chu cong dung; ky hieu km/ ty le: TK_268_ChuKyHieu
(defun td:style-manh () (if (tblsearch "STYLE" "TK_268_ChuManh") "TK_268_ChuManh" (td:style)))
(defun td:style-kh () (cond ((tblsearch "STYLE" "TK_268_ChuKyHieu") "TK_268_ChuKyHieu")
                            ((tblsearch "STYLE" "VNKT") "VNKT") (t nil)))

;; TEXT: hj/vj = nhom can le (1,2 = giua-giua ; 1,1 giua-day ; 1,3 giua-tren ; 2,2 phai-giua ; 4,2 fit/giua)
(defun td:text (s x y h rot hj vj layer color / )
  (td:text-s s x y h rot hj vj layer color (td:style)))
(defun td:text-s (s x y h rot hj vj layer color st / )
  (if (and layer st)
    (entmake
      (append
        (list '(0 . "TEXT") (cons 8 layer) (cons 7 st)
              (list 10 x y 0.0) (cons 40 h) (cons 41 0.8) (cons 50 rot)
              (cons 1 s) (cons 72 hj) (cons 73 vj) (list 11 x y 0.0))
        (if color (list (cons 62 color)) nil)))))

(defun td:line (x1 y1 x2 y2 layer)
  (if layer (entmake (list '(0 . "LINE") (cons 8 layer) (list 10 x1 y1 0.0) (list 11 x2 y2 0.0)))))

(defun td:pline (pts layer / )
  (if layer
    (entmake (append (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 layer)
                           '(100 . "AcDbPolyline") (cons 90 (length pts)) '(70 . 0))
                     (mapcar '(lambda (p) (list 10 (car p) (cadr p))) pts)))))

;;; Hinh hoc chuan (goc (ox,oy) = goc trai-duoi cua bang)
;;; chieu cao bang 90 : 8 hang, tu duoi len
(setq td:*rows*
  '(;; ten-hang  y-day  y-dinh  y-chu(giua)
    ("Doan thang - Doan cong"  0.0  20.0  10.0)
    ("Ly trinh"               20.0  28.0  24.0)
    ("Ten coc"                28.0  36.0  32.0)
    ("Khoang cach cong don"   36.0  46.0  41.0)
    ("Khoang cach le"         46.0  54.0  50.0)
    ("Cao do tu nhien"        54.0  66.0  60.0)
    ("Doc doc thiet ke"       66.0  78.0  72.0)
    ("Cao do thiet ke"        78.0  90.0  84.0)))
;; Ten hang thuc (co dau, TEXT tren layer 9302) viet bang \U+xxxx
(setq td:*hdr*
  (list "\U+0110o\U+1EA1n th\U+1EB3ng - \U+0110o\U+1EA1n cong"
        "L\U+00FD tr\U+00ECnh"
        "T\U+00EAn c\U+1ECDc"
        "Kho\U+1EA3ng c\U+00E1ch c\U+1ED9ng d\U+1ED3n"
        "Kho\U+1EA3ng c\U+00E1ch l\U+1EBB"
        "Cao \U+0111\U+1ED9 t\U+1EF1 nhi\U+00EAn"
        "D\U+1ED1c d\U+1ECDc thi\U+1EBFt k\U+1EBF"
        "Cao \U+0111\U+1ED9 thi\U+1EBFt k\U+1EBF"))

(defun td:y (H oy hbase) (+ oy 120.0 (* 10.0 (- H hbase))))   ; cao do -> toa do Y (TLD 1/100 = x10)

;; Khung bang + tieu de hang. L = chieu dai tuyen (m)
(defun td:khung (ox oy L / l2 l3 xr i r)
  (setq l2 (td:layer "TK-ADS-9302-") xr (+ ox 45.0 L 2.948))
  (foreach r td:*rows*   ; 9 duong ngang (day + dinh moi hang)
    (td:line ox (+ oy (cadr r)) xr (+ oy (cadr r)) l2))
  (td:line ox (+ oy 90.0) xr (+ oy 90.0) l2)
  (td:line ox oy ox (+ oy 90.0) l2)
  (td:line (+ ox 43.1) oy (+ ox 43.1) (+ oy 90.0) l2)
  (td:line xr oy xr (+ oy 90.0) l2)
  (setq i 0)
  (foreach r td:*rows*
    (td:text (nth i td:*hdr*) (+ ox 21.5) (+ oy (nth 3 r)) 2.0 0.0 4 2 l2 nil)
    (setq i (1+ i))))

;;; Ve toan bo.
;;; ox oy   : goc trai-duoi bang      hbase : cao do goc (thuong 0.0)
;;; cocs    : danh sach (ten  lytrinh(m)  cao_do_tu_nhien  cao_do_thiet_ke  chinh_cao)
;;;           vd  '(("1" 0.0 1.45 1.45 0.0) ("2" 9.17 1.34 1.48 0.14) ...)
(defun td:ve (ox oy L hbase cocs / x0 lD lC lT lN lH prev nat k x yg yd)
  (setq x0 (+ ox 45.0)
        lC (td:layer "TK-ADS-9303-") lD (td:layer "TK-ADS-9305-")
        lN (td:layer "KS-TUY-2401-") lH (td:layer "TK-ADS-9331-")
        lT (td:layer "TK-DBO-1101-"))
  ;; 9331 va DBO-1101 chi can khi co phan thiet ke
  (if (not (and lC lD lN (td:layer "TK-ADS-9302-") (td:style))) (td:err "Dung ve: thieu layer/style")
    (progn
      (td:khung ox oy L)
      (setq prev nil nat nil k 0)
      (foreach c cocs
        (setq x (+ x0 (cadr c)) yg (td:y (nth 2 c) oy hbase))
        ;; duong dong tu mep tren bang len diem dia hinh
        (td:line x (+ oy 90.0) x yg lD)
        ;; chu trong bang (xoay 90 do, can phai-giua, cach mep tren 1.0)
        (td:text (rtos (cadr c) 2 2) x (+ oy 45.0) 2.0 1.5708 2 2 lC 3)           ; cong don
        (td:text (rtos (nth 2 c) 2 2) x (+ oy 65.0) 2.0 1.5708 2 2 lC 3)           ; tu nhien
        ;; ten coc (xanh duong): coc so o day hang, coc chi tiet (D1, TD2, P2, TC2...) o dinh hang
        (if (wcmatch (car c) "#*")
          (td:text (car c) x (+ oy 29.0) 2.0 0.0 1 1 lC 5)
          ;; coc chi tiet sat nhau (khoang cach < 6): xoay 90 do de khong de chu len nhau
          (if (or (and prev (< (- (cadr c) (cadr prev)) 6.0))
                  (and (cadr (member c cocs)) (< (- (cadr (cadr (member c cocs))) (cadr c)) 6.0)))
            (td:text (car c) x (+ oy 35.0) 2.0 1.5708 2 2 lC 5)
            (td:text (car c) x (+ oy 35.0) 2.0 0.0 1 3 lC 5)))
        ;; khoang cach le giua hai coc: nam ngang neu du rong, xoay 90 neu coc sat nhau (< 6)
        (if prev
          (td:text (rtos (- (cadr c) (cadr prev)) 2 2) (/ (+ x (+ x0 (cadr prev))) 2.0)
                   (+ oy 50.0) 2.0 (if (< (- (cadr c) (cadr prev)) 6.0) 1.5708 0.0) 1 2 lC 3))
        ;; PHAN THIET KE: chi ve khi co so lieu (nth 3 = cao do thiet ke; nth 4 = chinh cao)
        (if (nth 3 c)
          (progn
            (setq yd (td:y (nth 3 c) oy hbase))
            (td:text (rtos (nth 3 c) 2 2) x (+ oy 89.0) 2.0 1.5708 2 2 lC 2)       ; thiet ke (vang)
            (if (nth 4 c) (td:text (rtos (nth 4 c) 2 2) (- x 1.0) (+ yd 2.0) 2.0 1.5708 0 1 lH nil))))
        (setq nat (cons (list x yg) nat) prev c))
      ;; Km dau/cuoi (xanh duong, giua-tren) trong hang Ly trinh
      (td:text "Km 0+0.00" (+ x0 5.567) (+ oy 26.4) 2.0 0.0 1 3 lC 5)
      (td:text (strcat "Km 0+" (rtos L 2 2)) (- (+ x0 L) 5.567) (+ oy 26.4) 2.0 0.0 1 3 lC 5)
      ;; duong tu nhien (polyline)
      (td:pline (reverse nat) lN)
      ;; duong thiet ke tim tuyen: chi ve khi TAT CA coc co cao do thiet ke
      (if (and lT (not (member nil (mapcar '(lambda (c) (nth 3 c)) cocs))))
        (td:pline (mapcar '(lambda (c) (list (+ x0 (cadr c)) (td:y (nth 3 c) oy hbase))) cocs) lT))
      (princ "\n[TRAC DOC] Xong. CHUA luu. Kiem tra bang screenshot."))))
;;; CHI DUNG khi ban ve dich TRONG va nguoi dung da dong y: sao chep dinh nghia layer/style tu 02.TNTK.dwg
;;; (mau, lineweight, font y nguyen). Chi tao cac layer ma ham td:ve can; khong dong vao layer khac.
(defun td:tao-layer-style (/ defs d)
  (setq defs
    (list (list "TK_268_BangTracDoc" 3)
          (list "TK_268_ChuTracDoc" 3)
          (list "TK_268_DuongDong" 8)
          (list "TK_268_TracDocTuNhien" 3)))
  (foreach d defs
    (if (not (tblsearch "LAYER" (car d)))
      (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
                     (cons 2 (car d)) '(70 . 0) (cons 62 (cadr d)) '(6 . "Continuous") '(370 . -3)))))
  (if (not (tblsearch "STYLE" "TK_268_ChuBang"))
    (entmake (list '(0 . "STYLE") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbTextStyleTableRecord")
                   (cons 2 "TK_268_ChuBang") '(70 . 0) '(40 . 0.0) '(41 . 0.8) '(50 . 0.0)
                   '(71 . 0) '(42 . 2.5) '(3 . "arial.ttf") '(4 . ""))))
  (princ "\n[TRAC DOC] da tao layer/style trac doc con thieu."))
;;; ===== Ly trinh dau/cuoi + ky hieu ty le (theo ban mau 02.TNTK.dwg) =====
;;; Layer 9307 (mau 3) + text style VNKT (VnArial.TTF, wf 1.0) - chi tao khi nguoi dung dong y.
(defun td:tao-layer-style-ky-hieu ()
  (if (not (tblsearch "LAYER" "TK_268_LyTrinh"))
    (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbLayerTableRecord")
                   (cons 2 "TK_268_LyTrinh") '(70 . 0) '(62 . 3) '(6 . "Continuous") '(370 . -3))))
  (if (not (tblsearch "STYLE" "TK_268_ChuKyHieu"))
    (entmake (list '(0 . "STYLE") '(100 . "AcDbSymbolTableRecord") '(100 . "AcDbTextStyleTableRecord")
                   '(2 . "TK_268_ChuKyHieu") '(70 . 0) '(40 . 0.0) '(41 . 1.0) '(50 . 0.0) '(71 . 0) '(42 . 1.0)
                   '(3 . "arial.ttf") '(4 . ""))))
  (princ))

(defun td:rect (x1 y1 x2 y2 layer)
  (entmake (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 layer) '(100 . "AcDbPolyline")
                 '(90 . 4) '(70 . 1) (list 10 x1 y1) (list 10 x2 y1) (list 10 x2 y2) (list 10 x1 y2))))

;; Nhan ly trinh dau/ cuoi: khung chu nhat + chu + que ngan, dat tai x coc, cao co dinh oy+155.9..oy+163.8
(defun td:km (s x oy / l7 w)
  (setq l7 (td:layer "TK-ADS-9307-") w (max 15.25 (* 15.25 (/ (strlen s) 9.0))))
  (if l7 (progn
    (td:rect (- x (/ w 2.0)) (+ oy 157.8) (+ x (/ w 2.0)) (+ oy 163.8) l7)
    (td:line x (+ oy 155.9) x (+ oy 157.8) l7)
    (td:text s x (+ oy 160.8) 2.0 0.0 1 2 l7 nil))))

;; Ky hieu ty le (tam giac + TLD xoay 90 + TLN) ben trai bang, tuong doi goc (ox, oy)
(defun td:ty-le (ox oy / l2 l7 st)
  (setq l2 (td:layer "TK-ADS-9302-") l7 (td:layer "TK-ADS-9307-"))
  (if (and l2 l7 (td:style-kh))
    (progn
      (entmake (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 l2) '(100 . "AcDbPolyline")
                     '(90 . 3) '(70 . 1)
                     (list 10 (+ ox 27.629) (+ oy 124.335)) (list 10 (+ ox 27.629) (+ oy 105.042))
                     (list 10 (+ ox 14.646) (+ oy 105.042))))
      (foreach m (list (list "TLD: 1/100" (+ ox 29.158) (+ oy 106.662) 14.362 '(0.0 1.0 0.0))
                       (list "TLN: 1/1000" (+ ox 13.833) (+ oy 103.834) 0.0 '(1.0 0.0 0.0)))
        (entmake (list '(0 . "MTEXT") '(100 . "AcDbEntity") (cons 8 l7) '(62 . 40) '(100 . "AcDbMText")
                       (list 10 (nth 1 m) (nth 2 m) 0.0) '(40 . 2.0) (cons 41 (nth 3 m)) '(71 . 1) '(72 . 1)
                       (cons 1 (car m)) (cons 7 (td:style-kh)) (cons 11 (nth 4 m)))))))
  (princ))

;; Goi sau td:ve:  (td:ky-hieu ox oy L)
(defun td:ky-hieu (ox oy L / x0)
  (setq x0 (+ ox 45.0))
  (td:km "Km 0+0.00" x0 oy)
  (td:km (strcat "Km 0+" (rtos L 2 2)) (+ x0 L) oy)
  (td:ty-le ox oy)
  (princ "\n[TRAC DOC] Da ve ly trinh dau/cuoi + ky hieu ty le. CHUA luu."))
;;; ===== Hang "Doan thang - Doan cong" (binh do tuyen) doc tu file .ntd (2026-11-25) =====
;; Tach chuoi theo ky tu sep (vd "\t")
(defun td:split (s sep / r i p)
  (setq r nil p 1 i 1)
  (while (<= i (strlen s))
    (if (= (substr s i 1) sep)
      (setq r (cons (substr s p (- i p)) r) p (1+ i)))
    (setq i (1+ i)))
  (reverse (cons (substr s p) r)))

;; Doc cac dong POLE cua .ntd -> danh sach (ten ly-trinh cao-do R goc-rad)
;; POLE <ten> <ly trinh> <cao do> <a> <R> <goc rad>  (goc = pi la thang; TDn/ Pn/ TCn = dau/ dinh/ cuoi duong cong)
(defun td:doc-ntd (file / f ln r tk)
  (setq f (open file "r") r nil)
  (if f
    (progn
      (while (setq ln (read-line f))
        (setq tk (td:split ln "\t"))
        (if (and (= (car tk) "POLE") (> (length tk) 6))
          (setq r (cons (list (nth 1 tk) (atof (nth 2 tk)) (atof (nth 3 tk)) (atof (nth 5 tk)) (atof (nth 6 tk))) r))))
      (close f))
    (td:err (strcat "Khong mo duoc file " file)))
  (reverse r))

;; Goc rad (0..2pi, pi = thang) -> chuoi "A = " kieu D°M'S.SS'' ; >180 thi lay am (-(360-goc))
(defun td:fmt-goc (ang / d ad dg mn sc)
  (setq d (* ang (/ 180.0 3.14159265358979)))
  (if (> d 180.0) (setq d (- d 360.0)))
  (setq ad (abs d) dg (fix ad) mn (fix (* (- ad dg) 60.0)) sc (* (- ad dg (/ mn 60.0)) 3600.0))
  (strcat (if (< d 0.0) "-" "") (itoa dg) "\U+00B0" (itoa mn) "'" (rtos sc 2 2) "''"))

;; MTEXT do (mau 1) can giua-day, layer chu trac doc, cao 2.0
(defun td:mtext-doan (txt x y lay)
  (entmake (list '(0 . "MTEXT") '(100 . "AcDbEntity") (cons 8 lay) '(62 . 1) '(100 . "AcDbMText")
                 (list 10 x y 0.0) '(40 . 2.0) '(41 . 0.0) '(71 . 5) '(72 . 1)
                 (cons 1 txt) (cons 7 (td:style)) '(11 1.0 0.0 0.0))))

;; Ve hang Doan thang - Doan cong.  poles = (td:doc-ntd ...) ; L = chieu dai tuyen
;; Theo ban mau 02.TNTK (da do): duong do (TK_268_DuongTKTimTuyen) nam ngang o oy+10.
;; Dinh goc A<0: hinh mai nha LOI LEN rong 12 cao 6, chu A=... tam o oy+8 (duoi duong).
;; Dinh goc A>0: hinh V LOM XUONG rong 12 sau 6, chu tam o oy+12 (tren duong).
;; Cong tron (P co R): hinh chu nhat ho day rong K (TD..TC), cao 4 (len neu A<0, xuong neu A>0); chu 3 dong can giua-giua.
;; Cuoi tuyen: chu "A = " de trong o oy+12.
(defun td:doan-cong (ox oy L poles / lt lr x0 yb i p pn pp1 ang phi rr tg kk pk dd sb se x neg vs hw)
  (setq lt (td:layer "TK-ADS-9303-") lr (td:layer "TK-DBO-1601-")
        x0 (+ ox 45.0) yb (+ oy 10.0) i 0 hw 6.0 vs (list (list x0 yb)))
  (if (not (and lt lr (td:style)))
    (td:err "Thieu layer/ style hang Doan thang - Doan cong -> go TDKT (khi nguoi dung dong y)")
    (progn
      (foreach p poles
        (setq ang (nth 4 p) x (+ x0 (cadr p)))
        (if (> (abs (- ang 3.14159265358979)) 0.000001)
          (progn
            (setq neg (> ang 3.14159265358979))
            (if (and (> (nth 3 p) 0.0) (> i 0) (< (1+ i) (length poles)))
              (progn   ; duong cong: P giua TD va TC
                (setq pn (nth (1- i) poles) pp1 (nth (1+ i) poles)
                      sb (+ x0 (cadr pn)) se (+ x0 (cadr pp1)) rr (nth 3 p)
                      phi (- 3.14159265358979 (abs (if neg (- 6.28318530717958 ang) ang)))
                      tg (* rr (/ (sin (/ phi 2.0)) (cos (/ phi 2.0))))
                      kk (* rr phi)
                      pk (* rr (- (/ 1.0 (cos (/ phi 2.0))) 1.0))
                      dd (- (* 2.0 tg) kk))
                (setq vs (cons (list sb yb) vs))
                (setq vs (cons (list sb (+ yb (if neg 4.0 -4.0))) vs))
                (setq vs (cons (list se (+ yb (if neg 4.0 -4.0))) vs))
                (setq vs (cons (list se yb) vs))
                (td:mtext-doan (strcat "A = " (td:fmt-goc ang) " R = " (rtos rr 2 2) "\\PD = " (rtos dd 2 2)
                                       " P = " (rtos pk 2 2) "\\PK = " (rtos kk 2 2) " T = " (rtos tg 2 2))
                               (/ (+ sb se) 2.0) (if neg (+ oy 8.0) (+ oy 12.0)) lt))
              (progn   ; dinh goc thuong
                (setq vs (cons (list (- x hw) yb) vs))
                (setq vs (cons (list x (+ yb (if neg 6.0 -6.0))) vs))
                (setq vs (cons (list (+ x hw) yb) vs))
                (td:mtext-doan (strcat "A = " (td:fmt-goc ang)) x (if neg (+ oy 8.0) (+ oy 12.0)) lt)))))
        (setq i (1+ i)))
      ;; diem cuoi tuyen: chu "A = " de trong nhu ban mau
      (td:mtext-doan "A = " (+ x0 L) (+ oy 12.0) lt)
      (setq vs (reverse (cons (list (+ x0 L) yb) vs)))
      (entmake (append (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 lr) '(100 . "AcDbPolyline")
                             (cons 90 (length vs)) '(70 . 0))
                       (mapcar '(lambda (v) (list 10 (car v) (cadr v))) vs)))
      (princ "\n[TRAC DOC] Da ve hang Doan thang - Doan cong. CHUA luu."))))
(princ "\n[TRAC DOC] da nap trac-doc-helpers.lsp")
