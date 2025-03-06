; Clipboard manager

clipboardHistory := []
; Biến cờ để đánh dấu khi nào đang thực hiện thao tác định dạng (không lưu vào lịch sử)
isFormatting := false
; Lưu trữ nội dung clipboard ban đầu khi thực hiện các thao tác định dạng
originalClip := ""

; Map đầy đủ tất cả các dấu tiếng Việt
global accentMap := Map(
    ; Nguyên âm thường
    "à", "a", "á", "a", "ả", "a", "ã", "a", "ạ", "a", 
    "ă", "a", "ằ", "a", "ắ", "a", "ẳ", "a", "ẵ", "a", "ặ", "a",
    "â", "a", "ầ", "a", "ấ", "a", "ẩ", "a", "ẫ", "a", "ậ", "a",
    "è", "e", "é", "e", "ẻ", "e", "ẽ", "e", "ẹ", "e",
    "ê", "e", "ề", "e", "ế", "e", "ể", "e", "ễ", "e", "ệ", "e",
    "ì", "i", "í", "i", "ỉ", "i", "ĩ", "i", "ị", "i",
    "ò", "o", "ó", "o", "ỏ", "o", "õ", "o", "ọ", "o",
    "ô", "o", "ồ", "o", "ố", "o", "ổ", "o", "ỗ", "o", "ộ", "o",
    "ơ", "o", "ờ", "o", "ớ", "o", "ở", "o", "ỡ", "o", "ợ", "o",
    "ù", "u", "ú", "u", "ủ", "u", "ũ", "u", "ụ", "u",
    "ư", "u", "ừ", "u", "ứ", "u", "ử", "u", "ữ", "u", "ự", "u",
    "ỳ", "y", "ý", "y", "ỷ", "y", "ỹ", "y", "ỵ", "y", "đ", "d",
    
    "À", "A", "Á", "A", "Ả", "A", "Ã", "A", "Ạ", "A",
    "Ă", "A", "Ằ", "A", "Ắ", "A", "Ẳ", "A", "Ẵ", "A", "Ặ", "A",
    "Â", "A", "Ầ", "A", "Ấ", "A", "Ẩ", "A", "Ẫ", "A", "Ậ", "A",
    "È", "E", "É", "E", "Ẻ", "E", "Ẽ", "E", "Ẹ", "E",
    "Ê", "E", "Ề", "E", "Ế", "E", "Ể", "E", "Ễ", "E", "Ệ", "E",
    "Ì", "I", "Í", "I", "Ỉ", "I", "Ĩ", "I", "Ị", "I",
    "Ò", "O", "Ó", "O", "Ỏ", "O", "Õ", "O", "Ọ", "O",
    "Ô", "O", "Ồ", "O", "Ố", "O", "Ổ", "O", "Ỗ", "O", "Ộ", "O",
    "Ơ", "O", "Ờ", "O", "Ớ", "O", "Ở", "O", "Ỡ", "O", "Ợ", "O",
    "Ù", "U", "Ú", "U", "Ủ", "U", "Ũ", "U", "Ụ", "U",
    "Ư", "U", "Ừ", "U", "Ứ", "U", "Ử", "U", "Ữ", "U", "Ự", "U",
    "Ỳ", "Y", "Ý", "Y", "Ỷ", "Y", "Ỹ", "Y", "Ỵ", "Y", "Đ", "D"
)

; Loại bỏ dấu tiếng Việt 
RemoveAccents(str) {
    result := ""
    Loop Parse, str
        result .= accentMap.Has(A_LoopField) ? accentMap[A_LoopField] : A_LoopField
    return result
}

; Thêm hàm để hiển thị cài đặt clipboard
AddClipboardSettings(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w380 h100", "Định dạng dán (Caps+F)")
    
    yPos += 25
    settingsGui.Add("Radio", "x20 y" . yPos . " vFormatOption1 Checked" . (pasteFormatMode = 1), 
                   "Dán với định dạng tên file code (mặc định)")
    
    yPos += 25
    settingsGui.Add("Radio", "x20 y" . yPos . " vFormatOption2 Checked" . (pasteFormatMode = 2), 
                   "Dán với định dạng không dấu")
    
    ; Giữ lại các tùy chọn khác nếu đã có
    if (pasteFormatMode = 3) {
        yPos += 25
        settingsGui.Add("Radio", "x20 y" . yPos . " vFormatOption3 Checked1", "Tùy chọn 3")
    }
    
    if (pasteFormatMode = 4) {
        yPos += 25
        settingsGui.Add("Radio", "x20 y" . yPos . " vFormatOption4 Checked1", "Tùy chọn 4")
    }
    
    return yPos + 40  ; Trả về vị trí y mới
}

; Khởi tạo clipboard khi script bắt đầu
InitClipboard()

; Khởi tạo theo dõi clipboard
InitClipboard() {
    global clipboardHistory
    
    ; Chỉ cần khởi tạo mảng rỗng và bắt đầu theo dõi clipboard
    clipboardHistory := []
    
    ; Theo dõi sự thay đổi clipboard
    OnClipboardChange(ClipChanged, 1)  ; Thêm ưu tiên 1 đảm bảo sự kiện được gọi sớm
}

; Xử lý khi clipboard thay đổi - Với cơ chế ngăn lỗi nâng cao
ClipChanged(Type) {
    global clipboardHistory, isFormatting, originalClip
    
    ; Kiểm tra nếu đang định dạng và A_Clipboard không phải là nội dung ban đầu
    if (isFormatting) {
        ; Không lưu thay đổi và thoát khỏi hàm
        return
    }
        
    if Type = 1 {
        try {
            ; Luôn thêm nội dung mới vào cuối mảng, kể cả khi trùng lặp
            if (A_Clipboard != "") {
                clipboardHistory.Push(A_Clipboard)
                
                ; Giới hạn kích thước lịch sử là 30 mục
                ; Nếu vượt quá 30, xóa mục cũ nhất (đầu mảng)
                while clipboardHistory.Length > 30
                    clipboardHistory.RemoveAt(1)
            }
        }
    }
}


; Hiển thị và cho phép chọn từ lịch sử clipboard theo thứ tự tăng dần - Tối ưu và đơn giản hóa
CapsLock & c:: {
    global clipboardHistory
    
    if (clipboardHistory.Length = 0) {
        MsgBox("Chưa có dữ liệu trong lịch sử clipboard.", "Thông báo", "Icon!")
        return
    }
    
    ; Tạo GUI cho lịch sử clipboard
    clipHistoryGui := Gui(, "Lịch sử Clipboard")
    clipHistoryGui.SetFont("s10")
    
    ; Tạo ListView - Đã xóa cột Thời gian
    LV := clipHistoryGui.Add("ListView", "x10 y10 w700 h400 Grid", ["STT", "Nội dung"])
    LV.OnEvent("DoubleClick", PasteSelected)
    LV.OnEvent("ContextMenu", ShowContextMenu)  ; Thêm xử lý chuột phải
    
    ; Điều chỉnh độ rộng cột
    LV.ModifyCol(1, 50)    ; STT
    LV.ModifyCol(2, 640)   ; Nội dung - Tăng độ rộng vì đã xóa cột Thời gian
    
    ; Thêm các mục vào ListView theo thứ tự tăng dần (từ cũ đến mới)
    for index, content in clipboardHistory {
        ; Giới hạn độ dài hiển thị
        displayContent := StrLen(content) > 100 ? SubStr(content, 1, 100) . "..." : content
        
        ; Hiển thị thứ tự tăng dần rõ ràng
        stt := index  ; STT từ 1 đến Length
        
        ; Thêm vào ListView theo thứ tự tăng dần - Không có cột Thời gian
        LV.Add(, stt, displayContent)
    }
    
    ; Chọn mục đầu tiên (cũ nhất) để người dùng có thể dễ dàng duyệt từ đầu
    LV.Modify(1, "Select Focus")
    
    ; Thêm nút Dán (với Default để phản hồi phím Enter) và nút Dán tất cả
    clipHistoryGui.Add("Button", "x10 y420 w100 Default", "Dán").OnEvent("Click", PasteSelected)
    clipHistoryGui.Add("Button", "x120 y420 w100", "Dán tất cả").OnEvent("Click", PasteAllItems)
    clipHistoryGui.Add("Button", "x230 y420 w100", "Xóa tất cả").OnEvent("Click", ClearAllHistory)
    
    ; Hiển thị GUI
    clipHistoryGui.Show("w720 h460")
    
    ; Hàm xử lý sự kiện khi người dùng chọn một mục để dán
    PasteSelected(*) {
        if (focused_row := LV.GetNext(0)) {
            global isFormatting
            
            ; Đánh dấu bắt đầu định dạng
            isFormatting := true
            
            ; Lưu trữ clipboard hiện tại
            originalClip := ClipboardAll()
            
            ; Lấy chỉ số tương ứng từ cột STT để truy cập đúng mục trong mảng
            selected_index := LV.GetText(focused_row, 1)
            A_Clipboard := clipboardHistory[selected_index]
            
            ClipWait(0.3)
            clipHistoryGui.Destroy()
            Send("^v")
            Sleep(100)  ; Tăng thời gian chờ
            
            ; Khôi phục clipboard ban đầu
            A_Clipboard := originalClip
            ClipWait(0.3)
            Sleep(100)  ; Đảm bảo clipboard được khôi phục hoàn toàn
            
            ; Đánh dấu kết thúc định dạng
            isFormatting := false
        }
    }
    
    ; Hàm dán tất cả các mục theo thứ tự - Không hiện hộp thoại xác nhận
    PasteAllItems(*) {
        global isFormatting, clipboardHistory
        
        ; Đánh dấu bắt đầu định dạng
        isFormatting := true
        
        ; Lưu trữ clipboard hiện tại
        originalClip := ClipboardAll()
        
        ; Đóng GUI trước khi dán
        clipHistoryGui.Destroy()
        
        ; Chuẩn bị nội dung kết hợp với dấu xuống dòng
        combinedContent := ""
        
        ; Kết hợp tất cả các mục với dấu xuống dòng
        for index, content in clipboardHistory {
            combinedContent .= content
            
            ; Thêm dấu xuống dòng nếu không phải mục cuối
            if (index < clipboardHistory.Length)
                combinedContent .= "`r`n"
        }
        
        ; Đặt toàn bộ nội dung vào clipboard
        A_Clipboard := combinedContent
        ClipWait(0.5)
        
        ; Dán nội dung
        Send("^v")
        Sleep(100)
        
        ; Khôi phục clipboard ban đầu
        A_Clipboard := originalClip
        ClipWait(0.5)
        
        ; Đánh dấu kết thúc định dạng
        isFormatting := false
    }
    
    ; Hàm xóa toàn bộ lịch sử clipboard - Không hiện hộp thoại xác nhận
    ClearAllHistory(*) {
        global clipboardHistory
        
        ; Xóa mảng và đóng GUI
        clipboardHistory := []
        clipHistoryGui.Destroy()
    }
    
    ; Hiển thị menu chuột phải
    ShowContextMenu(LV, Item, IsRightClick, X, Y) {
        if (Item = 0)  ; Nếu không có mục nào được chọn
            return
            
        ; Tạo menu
        contextMenu := Menu()
        contextMenu.Add("Dán", PasteSelected)
        contextMenu.Add("Dán không dấu", PasteWithoutAccents)
        contextMenu.Add("Dán định dạng tên file", PasteAsFilename)
        contextMenu.Add()  ; Thêm dấu phân cách
        contextMenu.Add("Xóa mục này", DeleteSelected)
        
        ; Hiển thị menu tại vị trí chuột
        contextMenu.Show(X, Y)
    }
    
    ; Hàm dán với định dạng không dấu
    PasteWithoutAccents(*) {
        if (focused_row := LV.GetNext(0)) {
            global isFormatting
            
            ; Đánh dấu bắt đầu định dạng
            isFormatting := true
            
            ; Lưu trữ clipboard hiện tại
            originalClip := ClipboardAll()
            
            ; Lấy chỉ số tương ứng và xử lý nội dung
            selected_index := LV.GetText(focused_row, 1)
            A_Clipboard := RemoveAccents(clipboardHistory[selected_index])
            
            ClipWait(0.3)
            clipHistoryGui.Destroy()
            Send("^v")
            Sleep(100)
            
            ; Khôi phục clipboard ban đầu
            A_Clipboard := originalClip
            ClipWait(0.3)
            Sleep(100)
            
            ; Đánh dấu kết thúc định dạng
            isFormatting := false
        }
    }
    
    ; Hàm dán với định dạng tên file code
    PasteAsFilename(*) {
        if (focused_row := LV.GetNext(0)) {
            global isFormatting, clipboardHistory
            
            ; Đánh dấu bắt đầu định dạng
            isFormatting := true
            
            ; Lưu trữ clipboard hiện tại
            originalClip := ClipboardAll()
            
            ; Lấy chỉ số tương ứng và xử lý nội dung
            selected_index := LV.GetText(focused_row, 1)
            
            ; Nếu có mục trước đó để làm tiền tố
            if (selected_index > 1) {
                prefix := clipboardHistory[selected_index - 1]
            } else if (clipboardHistory.Length > 1) {
                ; Sử dụng mục cuối cùng nếu không có mục trước đó
                prefix := clipboardHistory[clipboardHistory.Length]
            } else {
                ; Nếu chỉ có một mục trong lịch sử
                prefix := ""
            }
            
            ; Tạo tên file
            if (prefix)
                A_Clipboard := prefix . "_" . RemoveAccents(clipboardHistory[selected_index]) . "."
            else
                A_Clipboard := RemoveAccents(clipboardHistory[selected_index]) . "."
            
            ClipWait(0.3)
            clipHistoryGui.Destroy()
            Send("^v")
            Sleep(100)
            
            ; Khôi phục clipboard ban đầu
            A_Clipboard := originalClip
            ClipWait(0.3)
            Sleep(100)
            
            ; Đánh dấu kết thúc định dạng
            isFormatting := false
        }
    }
    
    ; Hàm xóa mục đã chọn
    DeleteSelected(*) {
        if (focused_row := LV.GetNext(0)) {
            global clipboardHistory
            
            ; Lấy chỉ số tương ứng từ cột STT
            selected_index := LV.GetText(focused_row, 1)
            
            ; Xóa khỏi mảng
            clipboardHistory.RemoveAt(selected_index)
            
            ; Cập nhật lại ListView
            LV.Delete()  ; Xóa tất cả các hàng
            
            ; Thêm lại các mục sau khi đã xóa
            for index, content in clipboardHistory {
                ; Giới hạn độ dài hiển thị
                displayContent := StrLen(content) > 100 ? SubStr(content, 1, 100) . "..." : content
                
                ; Thêm vào ListView theo thứ tự tăng dần
                LV.Add(, index, displayContent)
            }
            
            ; Nếu không còn mục nào
            if (clipboardHistory.Length = 0) {
                clipHistoryGui.Destroy()
                MsgBox("Đã xóa tất cả các mục trong lịch sử clipboard.", "Thông báo", "Icon!")
            }
        }
    }
}

; Paste previous clipboard - Cơ chế bảo vệ nội dung clipboard nâng cao
CapsLock & v:: {
    global isFormatting, clipboardHistory
    
    if (clipboardHistory.Length < 2) {
        MsgBox("Không có đủ nội dung trong lịch sử clipboard để dán mục trước đó.", "Thông báo", "Icon!")
        return
    }
    
    ; Đánh dấu bắt đầu định dạng
    isFormatting := true
    
    ; Lưu trữ clipboard hiện tại
    originalClip := ClipboardAll()
    
    ; Thực hiện dán nội dung trước đó
    A_Clipboard := clipboardHistory[clipboardHistory.Length - 1]
    ClipWait(0.3)
    Send("^v")
    Sleep(100)  ; Tăng thời gian chờ để đảm bảo dán hoàn tất
    
    ; Khôi phục clipboard ban đầu
    A_Clipboard := originalClip
    ClipWait(0.3)
    Sleep(100)  ; Đảm bảo clipboard được khôi phục hoàn toàn
    
    ; Đánh dấu kết thúc định dạng
    isFormatting := false
}

; Format and paste với cơ chế bảo vệ nội dung clipboard nâng cao
CapsLock & f:: { 
    global isFormatting, clipboardHistory
    
    ; Kiểm tra điều kiện tối thiểu
    if (clipboardHistory.Length < 1) {
        MsgBox("Không có nội dung trong lịch sử clipboard để định dạng.", "Thông báo", "Icon!")
        return
    }
    
    ; Kiểm tra điều kiện cho pasteFormatMode = 1 (yêu cầu ít nhất 2 mục)
    if (pasteFormatMode = 1 && clipboardHistory.Length < 2) {
        MsgBox("Định dạng tên file code yêu cầu ít nhất 2 mục trong lịch sử clipboard.", "Thông báo", "Icon!")
        return
    }
    
    ; Đánh dấu bắt đầu định dạng
    isFormatting := true
    
    ; Lưu trữ clipboard hiện tại
    originalClip := ClipboardAll()
    
    ; Định dạng và dán
    if (pasteFormatMode = 1 && clipboardHistory.Length >= 2) {
        ; Định dạng tên file code
        A_Clipboard := clipboardHistory[clipboardHistory.Length - 1] . "_" . 
                       RemoveAccents(clipboardHistory[clipboardHistory.Length]) . "."
    } else if (pasteFormatMode = 2) {
        ; Định dạng không dấu
        A_Clipboard := RemoveAccents(clipboardHistory[clipboardHistory.Length])
    } else {
        ; Các định dạng khác
        A_Clipboard := clipboardHistory[clipboardHistory.Length]
    }
    
    ; Dán và đảm bảo thời gian chờ đủ
    ClipWait(0.3)
    Send("^v")
    Sleep(100)  ; Tăng thời gian chờ để đảm bảo dán hoàn tất
    
    ; Khôi phục clipboard ban đầu
    A_Clipboard := originalClip
    ClipWait(0.3)
    Sleep(100)  ; Đảm bảo clipboard được khôi phục hoàn toàn
    
    ; Đánh dấu kết thúc định dạng
    isFormatting := false
}
