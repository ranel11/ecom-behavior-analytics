
# ecom-behavior-analytics: Продуктовая аналитика воронки и A/B-тестирование

![Python](https://img.shields.io/badge/Python-3.10%2B-blue)
![SQLite](https://img.shields.io/badge/SQLite-3.0%2B-lightgrey)
![Pandas](https://img.shields.io/badge/Pandas-2.0%2B-150458)
![Statsmodels](https://img.shields.io/badge/Statsmodels-A%2FB%20Testing-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

Сквозной пайплайн продуктовой аналитики и фреймворк для A/B-тестирования, построенный на логах кликстрима мультикатегорийного интернет-магазина (42M+ записей). Проект предназначен для моделирования пользовательских воронок, когортного Retention-анализа, построения дерева метрик, а также применения статистических методов снижения дисперсии (**CUPED** и **стратификация**) при принятии продуктовых решений.

---

## 📌 Описание проекта

Этот репозиторий демонстрирует полный цикл продуктовой аналитики для e-commerce сервисов (в контексте кейсов **Яндекс Маркета / Еды / Лавки**). Он решает ключевые бизнес-задачи:
* **Оптимизация конверсии:** Оценка потерь в воронке ($View \rightarrow Cart \rightarrow Purchase$) на уровне пользователей и сессий.
* **Математическая строгость:** Проектирование A/B-тестов, расчёт размер выборки и MDE (Minimum Detectable Effect), предотвращение проблемы подглядывания (Peeking Problem) и применение метода **CUPED**.
* **Data Engineering & ETL:** Эффективная потоковая загрузка гигабайтных CSV-файлов чанками в базе данных SQLite с оптимизацией индексов.

---

## 📊 Архитектура данных и EDA

Аналитический движок обрабатывает логи кликстрима из датасета [eCommerce behavior data from multi-category store (Kechinov)](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store).

### Схема данных (`events`)

| Колонка | Тип данных | Описание | Особенности обработки / Оптимизация |
| :--- | :--- | :--- | :--- |
| `event_time` | DATETIME | Время события (UTC) | Приведено к формату ISO для индексации в SQLite |
| `event_type` | VARCHAR | Тип действия: `view`, `cart`, `remove_from_cart`, `purchase` | Ключевая колонка для этапов воронки |
| `product_id` | INT64 | Уникальный ID товара | Ключ для рекомендательных алгоритмов |
| `category_id` | INT64 | Числовой ID категории товара | Используется для стратификации |
| `category_code` | VARCHAR | Категория товара (иерархическая string) | ~33% пропусков (`NULL`); заменяются на `unknown` |
| `brand` | VARCHAR | Название бренда | ~30% пропусков (`NULL`) |
| `price` | FLOAT64 | Цена товара в USD | Сильный правый хвост; требует логарифмирования или бутстрапа |
| `user_id` | INT64 | Уникальный ID пользователя | Ключ для анализа Retention, LTV и повторных покупок |
| `user_session` | UUID/VARCHAR | Уникальный ID сессии пользователя | Базовая единица для расчета Session CVR и Bounce Rate |

### Таблица классификации метрик

| Уровень | Название метрики | Математическое определение | Бизнес-цель / Назначение |
| :--- | :--- | :--- | :--- |
| **North Star Metric (NSM)** | **GMV (Gross Merchandise Value)** | $\sum (Price_{purchase})$ | Объем оборота платформы |
| **L1 Metric** | **Session Conversion Rate (CVR)** | $\frac{Sessions_{purchase}}{Sessions_{total}}$ | Эффективность конвертации входящего трафика |
| **L1 Metric** | **ARPPU** | $\frac{Total\ Revenue}{Unique\ Buyers}$ | Монетизация платящего пользователя |
| **L2 Metric** | **Cart-to-Purchase CVR** | $\frac{Sessions_{purchase}}{Sessions_{cart}}$ | Оценка трения на шаге оформления заказа |
| **Guardrail Metric** | **Bounce Rate** | $\frac{Sessions_{with\ 1\ view}}{Sessions_{total}}$ | Контроль ухода пользователей без взаимодействия |
| **Guardrail Metric** | **Remove-from-Cart Ratio** | $\frac{Events_{remove\_from\_cart}}{Events_{cart}}$ | Предотвращение раздражения пользователей от рекомендаций |

---

## 🔬 A/B-тестирование и математический аппарат

1. **Формулирование гипотезы:** Оценка эффективности нового алгоритма рекомендаций на карточке товара.
2. **Снижение дисперсии (CUPED):**
   $$\hat{Y}_{CUPED} = Y - \theta (X - \mathbb{E}[X])$$
   Использование пред-экспериментальной активности пользователя ($X$) для уменьшения дисперсии целевой метрики ($Y$), что увеличивает чувствительность теста (статистическую мощность) на 30–40%.
3. **Расчет размера выборки (Sample Size & MDE):** Оценка мощности ($\alpha = 0.05, \beta = 0.20$) с использованием Z-теста для пропорций и Welch's t-test / Bootstrap для среднего чека.

---

## 🛠️ Структура проекта
