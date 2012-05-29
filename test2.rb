# encoding: utf-8
$KCODE='UTF-8'

################################################################################
# License: 		MIT
# Author: 		Eugene Sugatov
#
# Copyright (C) 2012, Eugene Sugatov
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights 
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
# THE SOFTWARE.
################################################################################


require 'graph.model.rb'
require 'graph.editor.rb'

class Test < GraphEditor

	def initialize parent, dataModel
		super parent, dataModel
		bind '2', proc{route}
		hint 'СКМ - поиск решения.'
	end

	def route
		lock
		status 'Инициализация.'
		if @router and @router.alive?
			@router.kill 
			status 'Отбой.'
			unlock
			return
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
			unlock
		}
	end

	def go node, path, visited
		norm
		#puts "NODE: #{node.nodeID}"
		#path.each {|p| puts p}
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
		
		if s
			if sp < ss
				@short[node.nodeID] = path
				node.lbl.text = sp.round
			end
		else
			@short[node.nodeID] = path
			node.lbl.text = sp.round
		end

		#sleep 1
		sleep 0.25
		#lp = path.last
		#if lp then sleep lp.weight*3/1000 end

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
			#puts "PATH.INSPECT:\r\n #{path.inspect}"
			return 0
		end
	end

	def norm
		normalize text=false
	end

end
model = GraphModel.new
root = TkRoot.new {title 'Test Unit'}
Test.new root, model
Tk.mainloop
