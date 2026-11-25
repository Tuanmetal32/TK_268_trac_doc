;;; trac-doc-thietke.lsp - Ve phan THIET KE trac doc (duong thiet ke 1 dinh ty + duong cong dung parabol)
;;; Can nap truoc: trac-doc-helpers.lsp (td:layer, td:style, td:text, td:line, td:y). Layer/ style phai co san (go TDKT).
;;; Theo ban mau 02.TNTK.dwg: hang Cao do thiet ke, Doc doc thiet ke, chinh cao tim tuyen, duong tim (do), ghi chu cong dung.
;;; Khong ve hang "Doan thang - Doan cong" (la doan cong tren BINH DO, khong phai cong dung).

;; Thong so: s0 z0 = diem dau ; spvi zpvi = dinh doi doc (PVI) ; s1 z1 = diem cuoi ; R = ban kinh cong dung
(defun td:tk-thong-so (s0 z0 spvi zpvi s1 z1 R)
  (setq td:*s0* s0 td:*z0* z0 td:*sp* spvi td:*zp* zpvi td:*s1* s1 td:*z1* z1 td:*R* R
        td:*i1* (/ (- zpvi z0) (- spvi s0))
        td:*i2* (/ (- z1 zpvi) (- s1 spvi))
        td:*dl* (abs (- td:*i1* td:*i2*))
        td:*Lc* (* R td:*dl*)
        td:*T* (/ td:*Lc* 2.0)
        td:*sb* (- spvi td:*T*)
        td:*se* (+ spvi td:*T*)
        td:*zb* (+ z0 (* td:*i1* (- td:*sb* s0))))
  (list td:*i1* td:*i2* td:*Lc* td:*T* td:*sb* td:*se*))

;; Cao do thiet ke tai ly trinh s
(defun td:ze (s / x)
  (cond ((<= s td:*sb*) (+ td:*z0* (* td:*i1* (- s td:*s0*))))
        ((>= s td:*se*) (+ td:*zp* (* td:*i2* (- s td:*sp*))))
        (t (setq x (- s td:*sb*))
           (+ td:*zb* (* td:*i1* x) (/ (* (- td:*i2* td:*i1*) x x) (* 2.0 td:*Lc*))))))

;; Nhan "mui ten + CD + KM" (thay block LTTD, ve truc tiep, khong tao block moi)
;; side: 0 = nhu block LTTD goc; -1 = chu nam ben trai que; 1 = chu nam ben phai que (tranh chong chu khi cong ngan)
(defun td:nhan-lttd (x y cd km layer / )
  (td:nhan-lttd2 x y cd km layer 0))
(defun td:nhan-lttd2 (x y cd km layer side / xk xc)
  (cond ((= side -1) (setq xk (- x 5.2) xc (- x 0.5)))
        ((= side 1)  (setq xk (+ x 4.2) xc (+ x 2.9)))
        (t (setq xk (+ x 0.4695) xc (- x 0.1139))))
  (td:line x y x (+ y 18.0) layer)
  (td:line x y (+ x 0.54) (+ y 1.8) layer)
  (td:line x y (- x 0.54) (+ y 1.8) layer)
  ;; chu mong: style TK_268_ChuManh (calibril.ttf)
  (td:text-s km xk (+ y 3.2586) 1.8 1.5708 0 3 layer nil (td:style-manh))
  (td:text-s cd xc (+ y 3.2586) 1.8 1.5708 0 1 layer nil (td:style-manh)))

(defun td:circle (x y r layer)
  (if layer (entmake (list '(0 . "CIRCLE") (cons 8 layer) (list 10 x y 0.0) (cons 40 r)))))

(defun td:mtext (s x y layer / st)
  (setq st (td:style-manh))
  (if (and layer st)
    (entmake (list '(0 . "MTEXT") '(100 . "AcDbEntity") (cons 8 layer) '(100 . "AcDbMText")
                   (list 10 x y 0.0) '(40 . 2.0) '(41 . 0.0) '(71 . 5) '(72 . 1)
                   (cons 1 s) (cons 7 st) '(11 1.0 0.0 0.0)))))

;; Ve toan bo thiet ke.  cocs = (ten ly-trinh cao-do-tu-nhien nil nil) nhu td:ve ; hbase = 0.0
(defun td:thiet-ke (ox oy hbase cocs / x0 lC lH lT l21 l22 l23 l24 x z g yb yt pts s xs xe ym)
  (setq x0 (+ ox 45.0)
        lC (td:layer "TK-ADS-9303-") lH (td:layer "TK-ADS-9331-") lT (td:layer "TK-DBO-1101-")
        l21 (td:layer "TK-ADS-9321-") l22 (td:layer "TK-ADS-9322-")
        l23 (td:layer "TK-ADS-9323-") l24 (td:layer "TK-ADS-9324-"))
  (if (not (and lC lH lT l21 l22 l23 l24 (td:style)))
    (td:err "Thieu layer/ style thiet ke -> go TDKT (khi nguoi dung dong y)")
    (progn
      ;; 1) hang cao do thiet ke + chinh cao tren duong dong
      (foreach c cocs
        (setq x (+ x0 (cadr c)) z (td:ze (cadr c)) g (- z (nth 2 c)))
        (td:text (rtos z 2 2) x (+ oy 89.0) 2.0 1.5708 2 2 lC 2)
        (td:text (rtos g 2 2) (- x 1.0) (+ (td:y z oy hbase) (if (> g 0.005) 2.0 0.0)) 2.0 1.5708 0 1 lH nil))
      ;; 2) duong thiet ke (do): doan thang + parabol (buoc 0.5 m)
      (setq pts (list (list x0 (td:y td:*z0* oy hbase))))
      (setq s td:*sb*)
      (while (< s td:*se*)
        (setq pts (cons (list (+ x0 s) (td:y (td:ze s) oy hbase)) pts) s (+ s 0.5)))
      (setq pts (cons (list (+ x0 td:*se*) (td:y (td:ze td:*se*) oy hbase)) pts))
      (setq pts (cons (list (+ x0 td:*s1*) (td:y td:*z1* oy hbase)) pts))
      (entmake (append (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 lT) '(370 . 25)
                             '(100 . "AcDbPolyline") (cons 90 (length pts)) '(70 . 0))
                       (mapcar '(lambda (p) (list 10 (car p) (cadr p))) (reverse pts))))
      ;; 3) hang doc doc thiet ke (oy+66 .. oy+78)
      (setq yb (+ oy 66.0) yt (+ oy 78.0))
      (foreach sx (list td:*s0* td:*sp* td:*s1*)
        (td:line (+ x0 sx) yb (+ x0 sx) yt lC))
      (foreach seg (list (list td:*s0* td:*sp* td:*i1*) (list td:*sp* td:*s1* td:*i2*))
        (setq xs (+ x0 (car seg)) xe (+ x0 (cadr seg)) ym (/ (+ xs xe) 2.0))
        (if (> (caddr seg) 0.0) (td:line xs yb xe yt lC) (td:line xs yt xe yb lC))
        (td:text (strcat (rtos (* 100.0 (abs (caddr seg))) 2 2) "%") ym (+ oy 72.2) 2.0 0.0 1 1 lC 2)
        (td:text (rtos (- (cadr seg) (car seg)) 2 2) ym (+ oy 71.8) 2.0 0.0 1 3 lC 2))
      ;; 4) ghi chu cong dung
      (td:cong-dung ox oy hbase l21 l22 l23 l24)
      (princ "\n[TRAC DOC] Da ve thiet ke trac doc. CHUA luu."))))

(defun td:cong-dung (ox oy hbase l21 l22 l23 l24 / x0 xb xe xp yb ye yp xx zx)
  (setq x0 (+ ox 45.0) xb (+ x0 td:*sb*) xe (+ x0 td:*se*) xp (+ x0 td:*sp*)
        yb (td:y td:*zb* oy hbase) ye (td:y (td:ze td:*se*) oy hbase) yp (td:y td:*zp* oy hbase))
  ;; tiep tuyen BVC->PVI, PVI->EVC
  (td:line xb yb xp yp l21)
  (td:line xe ye xp yp l21)
  ;; vong tron dau/ cuoi cong va cuc tri
  (td:circle xb yb 1.0 l22)
  (td:circle xe ye 1.0 l22)
  (setq xx (* td:*i1* td:*R*))
  (if (and (> xx 0.0) (< xx td:*Lc*))
    (progn (setq zx (td:ze (+ td:*sb* xx)))
           (td:circle (+ xb xx) (td:y zx oy hbase) 1.0 l24)))
  ;; tam giac tai dinh
  (td:line xp (+ yp 1.0) (- xp 1.0) (- yp 1.0) l23)
  (td:line xp (+ yp 1.0) (+ xp 1.0) (- yp 1.0) l23)
  (td:line (- xp 1.0) (- yp 1.0) (+ xp 1.0) (- yp 1.0) l23)
  ;; ngoac + que + 2 dong thong so
  (entmake (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 l21) '(100 . "AcDbPolyline")
                 '(90 . 4) '(70 . 0)
                 (list 10 xb (+ oy 156.6)) (list 10 xb (+ oy 158.6)) (list 10 xe (+ oy 158.6)) (list 10 xe (+ oy 156.6))))
  (td:line xp (+ oy 158.6) xp (+ oy 154.6) l21)
  (td:mtext (strcat "R = " (rtos td:*R* 2 2) ", Di = 0.00") xp (+ oy 165.6) l21)
  (td:mtext (strcat "L = " (rtos td:*Lc* 2 2) ", Lvc = " (rtos td:*Lc* 2 2)) xp (+ oy 168.6) l21)
  ;; 3 nhan CD/ KM o tren cung
  (td:nhan-lttd2 xb (+ oy 170.6) (strcat "C\U+0110: " (rtos (td:ze td:*sb*) 2 2)) (strcat "KM0 + " (rtos td:*sb* 2 2)) l22 -1)
  (td:nhan-lttd2 xe (+ oy 170.6) (strcat "C\U+0110: " (rtos (td:ze td:*se*) 2 2)) (strcat "KM0 + " (rtos td:*se* 2 2)) l22 1)
  (td:nhan-lttd2 xp (+ oy 170.6) (strcat "C\U+0110: " (rtos td:*zp* 2 2)) (strcat "KM0 + " (rtos td:*sp* 2 2)) l23 0))
(princ "\n[TRAC DOC] da nap trac-doc-thietke.lsp")
