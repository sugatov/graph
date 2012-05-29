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
		super parent, dataModel, 800,480
		bind '2', proc{route}
		focus
		bind 'i', proc{puts "-\r\n#{@dm.to_s}-"}
		hint 'СКМ - поиск решения. I - отладочная инф-я'
	end

	def route
		if @router
			@router.kill
		end
		puts 'ROUTE START'
		status 'Routing...'
		@router = Thread.new{
			@nodes.each do |key,n|
				n.fill ColorNodeFix
			end
			@connections.each do |key,c|
				c.fill ColorConnFix
			end
			@steps = 0

			@routed = Hash.new
			
			if @nodes.count<2
				puts 'NO NODES TO ROUTE!'
			else
				find_route(@nodes[0],0,'0')
			end

			puts
			puts 'COMPLETE IN '+@steps.to_s+' STEPS.'
			puts
			status 'Complete.', ColorStatusInactive
		}
	end

	def find_route(node,weight,route)
		node.fill ColorNodeRouted
		@routed[node.nodeID] = true
		nc = @nodes.count
		cc = @connections.count

		avail = Array.new

		@nodes.each do |i,n|
			if @routed[i]
				next
			else
				id=node.nodeID.to_s+'->'+i.to_s
				if @connections[id]
					avail.push @connections[id]
				end
			end
		end
		
		avail = avail.sort_by{|val| val.weight}
		
		avail.each do |c|
			if @routed[c.dest.nodeID]
				next
			else
				sleep 0.25 + (c.weight/1000)
				weight+=c.weight
				@steps+=1
				route+='->'+c.dest.nodeID.to_s
				@routed[c.dest.nodeID]=true
				c.fill ColorConnRouted
				c.raise
				c.dest.fill ColorNodeRouted
				puts 'find route: '+route
				puts '	weight: '+weight.to_s+'.'
				find_route c.dest, weight, route
			end
		end
	end
end

model = GraphModel.new
root = TkRoot.new {title 'Test Unit'}
Test.new root, model
Tk.mainloop
