# encoding: utf-8
$KCODE='UTF-8'

require 'graph.model.rb'
require 'graph.editor.rb'

class Deijkstra < GraphEditor

	def initialize parent, dataModel
		super parent, dataModel, 800,480
		bind '2', proc{route}
		focus
		bind 'i', proc{puts "-\r\n#{@dm.to_s}-"}
		hint 'СКМ - поиск решения. I - отладочная инф-я'
	end

	def route
		status 'Инициализация.'
		puts '---------------------'
		if @router
			@router.kill
		end
		@router = Thread.new {
			v = Hash.new
			p = Array.new
			@short = Hash.new
			zero = @nodes[0]
			if zero
				v[zero.nodeID] = zero
				@short[zero.nodeID] = Array.new
				status 'Поиск...'
				go zero,p,v
				status 'Выполнено.'
			else
				status 'Недостаточно вершин!'
			end
			norm
		}
	end

	def go node, path, visited
		norm
		puts "NODE: #{node.nodeID}"
		path.each {|p| puts p}
		if path and path.count >0
			path.each do |p|
				p.raise
				p.fill 'red'
			end
		end
		l = path.last
		if l 
			#l.raise
			#l.fill 'red'
			l.source.fill '#003399'
			l.dest.fill '#0099ff'
		end

		s = @short[node.nodeID]
		ss = sum s
		sp = sum path
		puts '22'
		if s
			if sp < ss
				@short[node.nodeID] = path
				node.lbl.text = sp.round
			end
		else
			@short[node.nodeID] = path
			node.lbl.text = sp.round
		end

		sleep 1
		node.ways.each do |k,n|
			if not visited[k]
				visited4child = visited.clone
				path4child = path.clone
				c = @connections["#{node.nodeID}->#{n.nodeID}"]
				path4child.push c
				visited4child[k]=n
				go n, path4child, visited4child
			end
		end
	end

	def sum path
		if path and path.count > 0
			s = 0
			path.each {|p| s += p.weight}
			return s
		else
			puts "PATH.INSPECT:\r\n #{path.inspect}"
			return 0
		end
	end

	def norm
		@nodes.each do |k,n|
			#n.lbl.text = n.nodeID
			n.fill ColorNodeFix
		end
		@connections.each do |k,c|
			c.fill ColorConnFix
		end
	end

end
model = GraphModel.new
root = TkRoot.new {title 'Поиск кратчайших путей по алгоритму E.W.Deijkstra'}
Deijkstra.new root, model
Tk.mainloop
