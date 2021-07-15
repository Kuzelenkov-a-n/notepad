# encoding: utf-8
#
require 'sqlite3'

class Post
  SQLITE_DB_FILE = 'notepad.sl3'.freeze

  def self.post_types
    {
      'Memo' => Memo,
      'Task' => Task,
      'Link' => Link
    }
  end

  def self.create(type)
    post_types[type].new
  end

  def initialize
    @created_at = Time.now
    @text = []
  end

  def self.find_by_id(id)
    return if id.nil?

    db = SQLite3::Database.open(SQLITE_DB_FILE)
    db.results_as_hash = true
    begin
      result = db.execute('SELECT * FROM notepad WHERE rowid = ?', id)
    rescue SQLite3::SQLException => e
      puts "Таблица базы данных не найдена #{e}"
    end
    db.close

    return nil if result.empty?

    result = result[0]

    post = create(result['type'])
    post.load_data(result)
    post
  end

  def self.find_all(limit, type)
    db = SQLite3::Database.open(SQLITE_DB_FILE)

    db.results_as_hash = false

    query = 'SELECT rowid, * FROM notepad '
    query += 'WHERE type = :type ' unless type.nil?
    query += 'ORDER by rowid DESC '
    query += 'LIMIT :limit ' unless limit.nil?

    begin
      statement = db.prepare query
    rescue SQLite3::SQLException => e
      puts "Таблица базы данных не найдена #{e}"
    end

    statement.bind_param('type', type) unless type.nil?
    statement.bind_param('limit', limit) unless limit.nil?

    result = statement.execute!

    statement.close
    db.close

    result
  end

  def read_from_console
    # Этот метод должен быть реализован у каждого ребенка
  end

  def to_strings
    # Этот метод должен быть реализован у каждого ребенка
  end

  def load_data(data_hash)
    @created_at = Time.parse(data_hash['created_at'])
    @text = data_hash['text']
  end

  def to_db_hash
    {
      'type' => self.class.name,
      'created_at' => @created_at.to_s
    }
  end

  def save_to_db
    db = SQLite3::Database.open(SQLITE_DB_FILE)

    db.results_as_hash = true

    post_hash = to_db_hash

    begin
      db.execute(
        'INSERT INTO notepad (' +
          post_hash.keys.join(', ') +
          ") VALUES (#{('?,' * post_hash.size).chomp(',')})",
        post_hash.values
      )
    rescue SQLite3::SQLException => e
      puts "Таблица базы данных не найдена #{e}"
    end

    insert_row_id = db.last_insert_row_id

    db.close

    insert_row_id
  end

  def save
    file = File.new(file_path, 'w:UTF-8')

    to_strings.each { |string| file.puts(string) }

    file.close
  end

  def file_path
    current_path = File.dirname(__FILE__)

    file_time = @created_at.strftime('%Y-%m-%d_%H-%M-%S')

    "#{current_path}/#{self.class.name}_#{file_time}.txt"
  end
end
