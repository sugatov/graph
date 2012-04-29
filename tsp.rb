# encoding: utf-8
$KCODE='UTF-8'

require 'graph.model.rb'
require 'graph.editor.rb'

class TSP < GraphEditor

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
root = TkRoot.new {title 'Решение задачи коммивояжера'}
TSP.new root, model
Tk.mainloop
