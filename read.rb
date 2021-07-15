# encoding: utf-8
#
if Gem.win_platform?
  Encoding.default_external = Encoding.find(Encoding.locale_charmap)
  Encoding.default_internal = __ENCODING__

  [STDIN, STDOUT].each do |io|
    io.set_encoding(Encoding.default_external, Encoding.default_internal)
  end
end

require_relative 'lib/post'
require_relative 'lib/memo'
require_relative 'lib/link'
require_relative 'lib/task'

require 'optparse'

options = {}

OptionParser.new do |opt|
  opt.banner = 'Usage: read.rb [options]'

  opt.on('-h', 'Prints this help') do
    puts opt
    exit
  end

  opt.on('--type POST_TYPE', 'какой тип постов показывать (по умолчанию любой)') { |o| options[:type] = o }
  opt.on('--id POST_ID', 'если задан id - показываем подробно только этот пост') { |o| options[:id] = o }
  opt.on('--limit NUMBER', 'сколько последних постов показывать (по умолчанию все') { |o| options[:limit] = o }
end.parse!

result = if options[:id].nil?
           Post.find_all(options[:limit], options[:type])
         else
           Post.find_by_id(options[:id])
         end

if result.is_a? Post
  puts "Запись #{result.class.name}, id = #{options[:id]}"

  result.to_strings.each { |line| puts line }
else
  print '| id                 '
  print '| @type              '
  print '| @created_at        '
  print '| @text              '
  print '| @url               '
  print '| @due_date          '
  print '|'

  result.each do |row|
    puts
    row.each do |element|
      element_text = "| #{element.to_s.delete("\n")[0..17]}"
      element_text << ' ' * (21 - element_text.size)
      print element_text
    end

    print '|'
  end

  puts
end

if result.empty?
  puts 'В блокноте нет записей...'
else
  puts 'Хотите удалить какую-либо запись? Y/n'

  choice = STDIN.gets.chomp.downcase

  if choice == 'y'
    puts 'Введите "id" записи, которую хотите удалить:'
    post_id = STDIN.gets.chomp.to_i

    post_to_delete = Post.find_by_id(post_id)

    post_to_delete.delete_by_id(post_id)

    puts 'Запись успешно удалена из БД'
  else
    puts 'Выход из программы'
  end
end
