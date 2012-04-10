class GraphModel
	def initialize
		@nodes = Hash.new
		@connections = Hash.new
		@nextNode = 0
	end


	def addNode node
		@nodes[@nextNode] = node
		@nextNode += 1
	end

	def addConnection connection, id
		@connections[id] = connection
		connect connection.source, connection.dest
	end

	def deleteNode nodeID
		@nodes.each do |key,n|
			if n.ways[nodeID]
				n.ways.delete nodeID
			end
			id = Array.new ["#{n.nodeID.to_s}->#{nodeID.to_s}","#{nodeID.to_s}->#{n.nodeID.to_s}"]
			id.each do |id|
				if @connections[id]
					@connections[id].delete
					@connections.delete id
				end
			end
			
		end
		if nodeID != 0				#запрет на удаление нулевой вершины
			@nodes[nodeID].delete
			@nodes.delete nodeID
		else
			@nodes[0].ways.clear
		end
	end

	def connect source, dest
		source.ways[dest.nodeID] = dest
	end

	def to_s
		re = ""
		@nodes.each {|k,n| re += "Node #{n.to_s}\r\n"}
		@connections.each {|k,c| re += "Connection #{c.to_s}\r\n"}
		return re
	end

	attr_accessor :nodes, :connections, :nextNode
end