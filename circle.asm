.data
	tekst: .asciiz "Podaj promien okregu do narysowania: "
	nazwa_pliku: .asciiz "circle.bmp"
	.align 2
	header: .space 56
.text

#$s0 - szerokość/wysokość obrazka
#$s1 - szerokość obrazka z nadmiarem (szerokość musi być wielkrotnością 4)
#$s2 - adres bufora obrazka
#$s3 - adres do początku pliku
#$s4 - rozmiar całego obrazka
#$s5 - promień okręgu

#Wyświetl tekst
	li $v0, 4
	la $a0, tekst
	syscall
	
#Wczytaj promień okręgu
	li $v0, 5
	syscall
	move $s5, $v0
	
#Oblicz rozmiar obrazka - na podstawie promienia
	add $s0, $v0, $v0	#Podwaja promień i zapisuje w rejestrze s0
	addi $s0, $s0, 1	#Dodaje 1 do średnicy (środkowy piksel)
	
#Policz nadmiar - zaokrągla liczbę pikseli do 4 (w górę)
	mul $s1, $s0, 3		#Ilość pikseli w szerokości obrazka
	subi $s1, $s1, 1	#Odejmuje 1
	andi $s1, $s1, 0xfffffffc	#Maska bitowa - liczba całkowita powstała przez podzielenie $s1 przez 4
	addi $s1, $s1, 4	#Dodaj 4 - zaokrąglenie
#Wyświetl z nadmiarem
	li $v0, 1
	add $a0, $s1, $zero
	syscall
#Przygotuj nagłówek
	la $t0, header		#Pobiera adres do bufora nagłówka
	li $t1, 0x42		#Przygotuj pierwszy znak (z dokumentacji BMP)
	sb $t1, 2($t0)		#Zapisuje pierwszy znak
	li $t1, 0x4D		#Przygotuj drugi znak (z dokumentacji BMP)
	sb $t1, 3($t0)		#Zapisuje drugi znak
	
#Alokacja pamięci na obrazek i zapis nagłówka
	mul $t1, $s0, $s1	#Ile pikseli potrzeba na cały obraz - (wysokość) x (szerokość z nadmiarem)
	add $s4, $t1, $zero	#Zapamiętaj wartość - na później
	
	li $v0, 9		#Numer syscall alokacji
	add $a0, $t1, $zero	#Skopiuj ilość bajtów do alokacji (rozmiar)
	syscall
	add $s2, $v0, $zero	#Zapiamiętaj adres do zaalokowanej pamięci
	
	addi $t1, $t1, 54	#Rozmiar całego pliku
	sw $t1, 4($t0)		#Wpisz rozmiar całego pliku do nagłówka
	
	li $t1, 54		#54 - offset danych (rozmiar nagłówka)
	sw $t1, 12($t0)		#Zapisz offset
	li $t1, 40		#40 - długość do końca nagłówka
	sw $t1, 16($t0)		#Zapisz powyższą wartość
	add $t1, $s0, $zero	#Skopiuj szerokość/wysokość obrazka
	sw $t1, 20($t0)		#Zapisz szerokość obrazka
	sw $t1, 24($t0)		#Zapisz wysokość obrazka
	li $t1, 1		#1 - ilość wartstw kolorów
	sw $t1, 28($t0)		#Zapisz ilość warstw
	li $t1, 24		#24 - liczba bitów na piksel (3 kolory po 8 bitów każdy)
	sb $t1, 30($t0)		#Zapisz liczbę bitów na piksel
#Otwórz plik do zapisu
	li $v0, 13		#Numer syscall otwarcia pliku
	la $a0, nazwa_pliku	#Wczytanie adresu na nazwę pliku
	li $a1, 1		#1 - bo plik do odczytu
	li $a2, 0		#0 - flaga
	syscall
	add $s3, $v0, $zero	#Zapamiętanie wskaźnika na plik w $s3
#Zapisz nagłówek
	li $v0, 15		#Numer syscall zapisu do pliku
	add $a0, $s3, $zero	#Skopowianie wskaźnika na plik
	la $a1, header+2	#Początek zapisywanych danych
	li $a2, 54		#Ilość bitów do zapisania (rozmiar nagłówka)
	syscall
#Algorytm Bresenhama
	add $t0, $s5, $zero 	#Współrzędna X środka okręgu (X0) - równa promieniowi
	move $t1, $t0		#Współrzędna Y środka okręgu (Y0) - równa promieniowi
	li $t2, 5		#5
	mul $t3, $s5, 4		#4*r
	sub $t2, $t2, $t3	#d = 5 - 4*r	
	li $t3, 0		#Współrzędna X - aktualna
	move $t4, $t0		#Współrzędna Y - aktualna
	mul $t5, $t4, -2 	#deltaA = -2*r
	addi $t5, $t5, 5	#deltaA = 5 + deltaA = (5-2*r)
	mul $t5, $t5, 4		#deltaA = deltaA * r = (5-2*r) * 4
	li $t6, 12		#deltaB = 12

petla:
	bgt $t3, $t4, koniec	#Jeśli X>Y - cały okrąg narysowany
	
	#Ustawianie kolorów pikseli:
	#Ustaw kolor piksela 1
	sub $t7, $t0, $t3	# x0 - x
	sub $t8, $t1, $t4	# y0 - y
	mul $t7, $t7, 3		# *= 3 (bo po 3 piksele na jeden punkt)
	mul $t8, $t8, $s1	# *= wielkość_wiersza (bo przesunięcie o ileśtam linii w dół
	add $t7, $t7, $t8	# Obecna pozycja piksela
	add $t7, $t7, $s2	# Pozycja piksela względem początku pliku (dodaję do adresu początku pliku)
	li $v0, 0xff		#Kolor na czarny
	sb $v0, ($t7)		#Kolor niebieski
	sb $v0, 1($t7)		#Kolor zielony
	sb $v0, 2($t7)		#Kolor czerwony
	#Ustaw kolor piksela 2
	sub $t7, $t0, $t3 #x0 - x
	add $t8, $t1, $t4 #y0 - y
	mul $t7, $t7, 3 # *= 3
	mul $t8, $t8, $s1 # *= wielkość_wiersza
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Ustaw kolor piksela 3
	add $t7, $t0, $t3 #x0 - x
	sub $t8, $t1, $t4 #y0 - y
	mul $t7, $t7, 3 # *= 3
	mul $t8, $t8, $s1 # *= wielkość_wiersza
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Ustaw kolor piksela 4
	add $t7, $t0, $t3 #x0 - x
	add $t8, $t1, $t4 #y0 - y
	mul $t7, $t7, 3 # *= 3
	mul $t8, $t8, $s1 # *= wielkość_wiersza
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Ustaw kolor piksela 5
	sub $t7, $t0, $t4 #x0 - y
	sub $t8, $t1, $t3 #y0 - x
	mul $t7, $t7, 3 # *= 3
	mul $t8, $t8, $s1 # *= wielkość_wiersza
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Ustaw kolor piksela 6
	sub $t7, $t0, $t4 #x0 - x
	add $t8, $t1, $t3 #y0 - y
	mul $t7, $t7, 3 # *= 3
	mul $t8, $t8, $s1 # *= wielkość_wiersza
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Ustaw kolor piksela 7
	add $t7, $t0, $t4 #x0 - x
	sub $t8, $t1, $t3 #y0 - y
	mul $t7, $t7, 3 # *= 3
	mul $t8, $t8, $s1 # *= wielkość_wiersza
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Ustaw kolor piksela 8
	add $t7, $t0, $t4 #x0 - x
	add $t8, $t1, $t3 #y0 - y
	mul $t7, $t7, 3 # *= 3
	mul $t8, $t8, $s1 # *= wielkość_wiersza
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Kolorów pikseli ustawione
	
	bgtz $t2, d0		# d > 0   idź to d0
	# d <= 0
	add $t2, $t2, $t6	# d += deltaB
	addi $t3, $t3, 1	# x += 1
	addi $t5, $t5, 8	# deltaA += 2*4
	addi $t6, $t6, 8	# deltaB += 2*4
	b dalej 		
d0:
	# d > 0
	add $t2, $t2, $t5	#d += deltaA
	subi $t4, $t4, 1	#y -= 1
	addi $t3, $t3, 1	#x += 1
	addi $t5, $t5, 16	#deltaA += 4*4
	addi $t6, $t6, 8	#deltaB += 2*4
dalej:
	b petla			#Skocz do następnego kroku
koniec:
#Zapisz resztę pliku
	li $v0, 15		#Numer syscall do zapisu do pliku
	add $a0, $s3, $zero	#Skopiowanie wskaźnika na plik
	add $a1, $s2, $zero	#Skopiowanie adresu bufora
	add $a2, $s4, $zero	#Skopiowanie ilości pikseli obrazka
	syscall
#Zamknij plik
	li $v0, 16		#Numer syscall do zamknięcia pliku
	add $a0, $s3, $zero	#Skopiowanie wskaźnika na plik
	syscall
#Zakończ program
	li $v0, 10		#Numer syscall do zakończenia programu
	syscall
