
require 'erb'
require 'cgi'
require 'todo_list/todo_controller'
require 'todo_list/file_parser'

module Redcar
  class TodoList

    def self.menus
      Menu::Builder.build do
        sub_menu "Project" do
          item "Todo List", TodoList::ViewTodoListCommand
        end
      end
    end

    def self.keymaps
      map = Redcar::Keymap.build("main",[:osx,:linux,:windows]) do
        link "Alt+Shift+T", TodoList::ViewTodoListCommand
      end
      [map]
    end

    def self.storage
      @@storage ||= begin
        storage = Plugin::Storage.new('todo_list_plugin')
        storage.set_default('included_suffixes', ['.java','.rb','.groovy','.erb','.gsp','.html','.js'])
        storage.set_default('excluded_files', ['jquery.js','prototype.js'])
        storage.set_default('excluded_dirs', ['.svn','.git'])
        storage.set_default('require_colon', true)
        storage.set_default('tags', ['TODO','IMPROVE','CHANGED','OPTIMIZE','NOTE'])
        storage
      end
    end

    class ViewTodoListCommand < Redcar::Command
      sensitize :open_project
      def execute
        project = Project::Manager.in_window(win)
        controller = TodoController.new(project.home_dir)
        tab = win.new_tab(HtmlTab)
        tab.html_view.controller = controller
        tab.icon = :document_list
        tab.focus
      end
    end
  end
end
