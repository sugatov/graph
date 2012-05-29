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


class GraphModel

	attr_accessor :nodes, :connections, :nextNode



	def initialize
		@nodes = Hash.new
		@connections = Hash.new
		@nextNode = 0
	end


	def reset
		@nodes.clear
		@connections.clear
		@nextNode = 0
	end


	def addNode node
		@nodes[@nextNode] = node
		@nextNode += 1
	end

	def addConnection connection  #, id
		id = connectionID connection.source, connection.dest
		@connections[id] = connection
		connect connection.source, connection.dest
	end

	def connectionID source,dest
		return source.nodeID.to_s+'->'+dest.nodeID.to_s
	end
	def connectionPairID source,dest
		return Array.new [
			connectionID(source,dest),
			connectionID(dest,source)
		]
	end

	def deleteNode nodeID
		node = @nodes[nodeID]
		@nodes.each do |key,n|
			if n.ways[nodeID]
				n.ways.delete nodeID
			end
			#id = Array.new ["#{n.nodeID.to_s}->#{nodeID.to_s}","#{nodeID.to_s}->#{n.nodeID.to_s}"]
			#id = Array.new [connectionID(n,node), connectionID(node,n)]
			id = connectionPairID n,node
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

	def deleteConnection connectionID
		@connections[connectionID].delete
		@connections.delete connectionID
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

	
end