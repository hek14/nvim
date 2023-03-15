# 要分清楚每一个结构/class/function的指责, 不要越界

# M: the out most public API(manage scatter/gather/done)
M是一个prcoess manager的角色, send的时候按照file去分发,retrieve函数本质上是遍历各个child
M没有send ticket的概念, 也不应该维护真正的data, 因为它只是一个proxy, 真正的活还是process干的

maps: 
file -> child  (created in send)

# process(child)
maps:
file,pos -> latest ticket (always latest)
ticket: {input,output}
ticket.input 
ticket.output -> tbl[file,position] = scope

# tickets (corresponds to send, not filetick)
每一次send都带有tick, return的时候也对应的有这个tick
old ticket???
