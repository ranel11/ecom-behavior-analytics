import sqlite3
import pandas as pd
import time

# Пути к файлам и параметры
csv_file_path = '2019-Nov.csv'  # Или '2019-Oct.csv' (укажи имя своего файла)
db_file_path = 'ecommerce.db'
table_name = 'events'

start_time = time.time()
print(f"🚀 Начинаем импорт файла '{csv_file_path}' в SQLite БД '{db_file_path}'...")

# Создаем подключение
conn = sqlite3.connect(db_file_path)

# Оптимизируем настройки SQLite для быстрой записи
conn.execute("PRAGMA journal_mode = WAL;")
conn.execute("PRAGMA synchronous = NORMAL;")
conn.execute("PRAGMA cache_size = -1000000;") # 1 ГБ RAM под кэш

chunksize = 100_000
total_rows = 0

# Чтение и запись чанками по 100 000 строк
for i, chunk in enumerate(pd.read_csv(csv_file_path, chunksize=chunksize)):
    chunk.to_sql(table_name, conn, if_exists='append', index=False)
    total_rows += len(chunk)
    
    if (i + 1) % 50 == 0 or i == 0:
        print(f"Загружено строк: {total_rows:,}")

print(f"✅ Все данные успешно загружены! Всего строк: {total_rows:,}")

# Создаем базовые индексы для работы SQL-запросов
print("⚡ Создание индексов по user_id, user_session, event_type, event_time...")
cursor = conn.cursor()
cursor.execute(f"CREATE INDEX IF NOT EXISTS idx_events_user_id ON {table_name}(user_id);")
cursor.execute(f"CREATE INDEX IF NOT EXISTS idx_events_user_session ON {table_name}(user_session);")
cursor.execute(f"CREATE INDEX IF NOT EXISTS idx_events_type ON {table_name}(event_type);")
cursor.execute(f"CREATE INDEX IF NOT EXISTS idx_events_time ON {table_name}(event_time);")

conn.commit()
conn.close()

elapsed_min = round((time.time() - start_time) / 60, 2)
print(f"🎉 Загрузка и индексация завершены за {elapsed_min} мин!")
