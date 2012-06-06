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


Infinity = +1.0/0.0


class Dijkstra < GraphEditor

	def initialize parent, dataModel
		super parent, dataModel

		@visualizer = true

		focus
		bind '2', proc{route}
		bind 'r', proc{route}
		bind 'Control-2', proc{|e| showRoute e.x,e.y}
		bind 'v', proc{toggleVis}
		
		hint 'M3/R - поиск решения. Control-M3 - показать путь до вершины. V - вкл/выкл визуализацию.'

		bv = imgButton 'btn.vis.gif', '3', proc{toggleVis}
		br = imgButton 'btn.route.gif', '3', proc{route}		
	end

	
	def route
		if @router and @router.alive?
			@router.kill
			unlock
			status 'операция отменена.'
			norm
			return
		end
		
		if @nodes.count < 2
			status 'недостаточно вершин!', '#D85F05'
			return
		end

		normalize
		
		@router = Thread.new{
			lock

			@ws = Hash.new
			@nodes.each do |k,n|
				@ws[k] = k==0 ? 0 : Infinity
			end
			checklist = Hash.new
			@parents = Hash.new

			check @nodes[0]
			checklist[0] = true

			catch :infinity do
				while checklist.count < @ws.count do
					val = nil
					catch :find do
						@vs = @ws.sort_by{|k,v| v} 		# Hash преобразуется в Array и сортируется по значению
						@vs.each do |k|
							if k[1]==Infinity
								status 'найдены недосягаемые вершины!', '#D85F05'
								throw :infinity
							end
							if not checklist[k[0]]
								val = k[0]
								throw :find
							end
						end
					end
					if val
						check @nodes[val]
						checklist[val] = true
					end
				end
			end

			unlock
		}

	end


	def check node
		status "вершина: #{node.nodeID}"
		if @visualizer
			node.fill ColorNodeRouted
			sleep 1
		end
		nw = @ws[node.nodeID]
		ways = Array.new
		node.ways.each do |k,n|
			ways.push @connections[@dm.connectionID node,n]
		end
		ways = ways.sort

		ways.each do |w|
			status "вершина: #{node.nodeID}, ребро -> #{w.dest.nodeID}"
			if @visualizer
				w.raise
				w.fill ColorConnRouted
				sleep 0.5
			end
			id = w.dest.nodeID
			if nw + w.weight < @ws[id]
				@ws[id] = nw + w.weight
				@parents[id] = node.nodeID
				w.dest.text((nw + w.weight).round, '#000000')
			end
		end
		norm
	end

	def showRoute x,y
		fn = findNode x,y
		if not fn
			status 'вершина не указана!','#D85F05'
		else
			if @ws and @ws[fn.nodeID] and @ws[fn.nodeID] < Infinity
				n = fn.nodeID
				while n != 0
					n = markParentRib n
				end
				Thread.new{
					sleep 1
					norm
				}
			else
				status 'путь не найден!','#D85F05'
			end
		end
	end
	def markParentRib n
		p = @parents[n]
		if p
			c = @connections[@dm.connectionID @nodes[p], @nodes[n]]
			c.raise
			c.fill ColorConnRouted
			return p
		else
			return false
		end
	end

	def toggleVis
		@visualizer = @visualizer==true ? false : true
		if @visualizer
			status 'визуализация ВКЛ'
		else
			status 'визуализация ВЫКЛ'
		end
	end

	def norm
		normalize text=false
	end


end



model = GraphModel.new
root = TkRoot.new {title 'Поиск кратчайших путей по алгоритму Dijkstra'}
dijkstra = Dijkstra.new root, model

require 'dijkstra.controls.rb'
controlstop = TkToplevel.new{title 'Функции'}
controls = DijkstraControls.new controlstop, dijkstra


require 'debugview.rb'
dbgtop = TkToplevel.new {title 'Debug'}
dbg = DebugView.new dbgtop

dijkstra.focus
dijkstra.bind 'z', proc{dbg.message ColorSchemes.inspect}


Tk.mainloop
