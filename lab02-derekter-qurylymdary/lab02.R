# Зертханалық сабақ №2
# R тіліндегі деректер құрылымдары.
# Vector, Matrix, List, Factor, Data Frame, Tibble.

library(tibble)

# ==== 1-тапсырма. 20 элементтен Vector жасау ====
student_age <- c(18, 19, 18, 20, 19, 18, 21, 20, 19, 18,
                 20, 19, 18, 21, 20, 19, 18, 20, 19, 21)
student_age
length(student_age)

# ==== 2-тапсырма. 5×5 Matrix құру ====
m <- matrix(1:25, nrow = 5, ncol = 5)
m
dim(m)

# ==== 3-тапсырма. Matrix элементтерінің қосындысы ====
sum(m)
rowSums(m)
colSums(m)

# ==== 4-тапсырма. Бір студент туралы List ====
student <- list(
  name = "Айдана",
  age = 19,
  group = "ИТ-23-1",
  average_grade = 4.5,
  scholarship = TRUE
)
student
student$name
student$age
student$group

# ==== 5-тапсырма. Factor құру ====
study_type <- factor(c(
  "Грант", "Ақылы", "Грант", "Ақылы", "Грант", "Ақылы", "Грант"
))
study_type
levels(study_type)
table(study_type)

course <- factor(c("1-курс", "2-курс", "3-курс", "4-курс", "2-курс", "4-курс"),
                 levels = c("1-курс", "2-курс", "3-курс", "4-курс"))
table(course)

# ==== 6-тапсырма. 10 студенттен Data Frame ====
students <- data.frame(
  Name = c("Айдана", "Алихан", "Аружан", "Дастан", "Мадина",
           "Нұржан", "Әлия", "Ермек", "Жанар", "Бекзат"),
  Age = c(18, 19, 18, 20, 19, 18, 21, 20, 19, 18),
  Grade = c(4.5, 4.2, 4.8, 3.9, 4.6, 4.0, 4.7, 4.1, 4.4, 3.8),
  Study = c("Грант", "Ақылы", "Грант", "Грант", "Ақылы",
            "Грант", "Грант", "Ақылы", "Грант", "Ақылы")
)
students
str(students)
head(students)
tail(students)
dim(students)

# ==== 7-тапсырма. Әр құрылымның класы ====
class(student_age)
class(m)
class(student)
class(study_type)
class(students)

# ==== 8-тапсырма. Tibble құрылымымен танысу ====
students_tbl <- as_tibble(students)
students_tbl
class(students_tbl)

# ==== Қосымша тапсырма. Құрылымдарды салыстыру ====
comparison <- data.frame(
  Құрылым = c("Vector", "Matrix", "List", "Factor", "Data Frame", "Tibble"),
  Өлшемі = c("1D", "2D", "1D (кірістірілген)", "1D", "2D", "2D"),
  Типтер = c("бір тип", "бір тип", "әртүрлі", "категория", "баған ішінде бір тип", "баған ішінде бір тип"),
  Класы = c(class(student_age), class(m)[1], class(student), class(study_type),
            class(students), class(students_tbl)[1]),
  Мысал = c("c(1,2,3)", "matrix(1:25,5)", "list(a=1,b='x')", "factor(c('A','B'))",
            "data.frame(...)", "tibble(...)")
)
print(comparison, right = FALSE)
