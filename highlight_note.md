Normal : 正常的全局模式下的高亮组
NormalFloat : 浮动窗口的全局高亮组
Visual : 可视模式

CursorLine : 设置了 cursorline 后高亮当前行
CursorColumn : 设置了 cursorcolumn 后高亮当前列
ColorColumn : 当设置了 colorcolumn 和 textwidth 的时候，高亮指定列（textwidth 可以指定一个字符列的列数）

Folded : 当前折叠行 (非侧边栏)

CursorLineNr : 当前侧边栏中的行号高亮组
CursorLineSign : 侧边栏中的当前行的符号行高亮组
CursorLineFold : 侧边栏中的当前行的折叠行高亮组

LineNr : 侧边栏中的非当前行号的其他行号的高亮组
LineNrAbove : 侧边栏中的非当前行号的上面行号的高亮组
LineNrBelow : 侧边栏中的非当前行号的下面行号的高亮组
SignColumn : 侧边栏中的非当前行的其他符号行高亮组
FoldColumn : 侧边栏中的非当前行的其他折叠行高亮组

MsgArea : cmdline 回显信息的高亮组
ModeMsg : 当 set showmode 时，关于当前模式的描述情况的高亮组
MoreMsg : 在 more 模式中，显示的左下角字样（-- 更多 --）
Question : 当输入 cmd 命令后，命令如果需要确认，会弹出一组文本，该高亮组定义文本的显示方式, 如输入 :hi 后，请按 ENTER 或其它命令继续 这则消息
WarningMsg : 命令行中的警告信息
ErrorMsg : 命令行中的错误信息
MsgSeparator : 当 cmdline 中的消息超过整个屏幕的最大宽度时，将在上发出现一个分隔符，该分割符高亮组由此定义
QuickFixLine : vim.diagnostic.setloclist() 的快速修复列表高亮组

DiffAdd : 差异模式中新增的内容的高亮组
DiffChange : 差异模式中更改的内容的高亮组
DiffDelete : 差异模式中删除的内容的高亮组
DiffText : 差异模式中缺少的内容的高亮组

NonText : 在行尾的 eol ↴ 符号高亮组
Conceal : 如何显示隐藏字符（待定）
Whitespace : 空白字符
WinSeparator : 多个窗口之间的分隔符
EndOfBuffer : Buffer 内没有任何内容的地方（也没有换行符，但在可视中）

Menu : 菜单
Pmenu : 补全菜单的全局高亮组
PmenuSel : 补全菜单中当前选中项目的高亮组
PmenuSbar : 补全菜单中整个滚动条的高亮组
PmenuThumb : 补全菜单中当前所在的滚动条的高亮组

MatchParen: 配对的括号

SpellBad : 坏词的高亮组
SpellCap : 本应该大写开头的单词变成了小写的高亮组
SpellRare: 很少用过的单词

TabLine : 当前未选中的其他 tab
TabLineFill : 整个 tabline
TabLineSel : 当前选中的 tab


Search : search 模式中，其他匹配位置的高亮组
CurSearch : serach 时，当前光标所在单词的高亮设置
IncSearch : serach 模式中，光标在当前的位置的高亮组（由于光标在 cmdline 中，所以主屏幕上会用该高亮组标识光标位置）
Substitute : %s 代替模式下字符高亮

Directory : netrw 浏览器中目录的高亮组
Title : 标题

StatusLine : 状态栏的高亮组
Scrollbar : 滚动条
StatusLineNC : 未聚焦状态栏的高亮组

WinBar : winbar
WinBarNC: 未聚焦的 winbar

SpecialKey : 特殊的按键（ 如 <ctrl+b>）

-- # ---

Cursor : 当前光标（没啥用，terminal 会覆盖，只有在等待 whick_key 的时候才能看见他）
lCursor : 同上，没啥用
CursorIM : 同上，没啥用

TermCursor : 终端插入模式, 以聚焦的光标高亮组
TermCursorNC : 终端插入模式，未聚焦的光标高亮组
NormalNC : 非聚焦的全局模式下的高亮组

WildMenu: 补全横向菜单

VisualNOS: ??
SpecialKey: ??
