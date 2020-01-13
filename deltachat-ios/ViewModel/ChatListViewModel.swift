import UIKit

typealias VoidFunction = ()->Void

protocol ChatListViewModelProtocol {
    var onChatListUpdate: VoidFunction? { get set }
    var chatsCount: Int { get }
    var archivedChatsCount: Int { get }
    func chatIdFor(indexPath: IndexPath) -> Int?
    func msgIdFor(indexPath: IndexPath) -> Int?
    func chatSummaryFor(indexPath: IndexPath) -> DcLot
    func chatDetailFor(indexPath: IndexPath) -> ChatListCellViewModelProtocol
    func deleteChat(chatId: Int)
    func archieveChat(chatId: Int)

}

protocol ChatListCellViewModelProtocol {

}

class ChatListCellViewModel: ChatListCellViewModelProtocol {

}

class ChatListViewModel: ChatListViewModelProtocol {
    func msgIdFor(indexPath: IndexPath) -> Int? {
        return chatList.getMsgId(index: indexPath.row)
    }

    func chatIdFor(indexPath: IndexPath) -> Int? {
        return chatList.getChatId(index: indexPath.row)
    }

    var archivedChatsCount: Int {
        let chatList = dcContext.getChatlist(flags: DC_GCL_ARCHIVED_ONLY, queryString: nil, queryId: 0)
        return chatList.length
    }

    var onChatListUpdate: VoidFunction?

    var chatsCount: Int {
        return 0
    }

    private var chatList: DcChatlist {
        var gclFlags: Int32 = 0
        if showArchive {
            gclFlags |= DC_GCL_ARCHIVED_ONLY
        }
        return dcContext.getChatlist(flags: gclFlags, queryString: nil, queryId: 0)
    }

    private var searchActive: Bool = false
    private var dcContext: DcContext
    private var showArchive: Bool

    init(dcContext: DcContext, showArchive: Bool) {
        self.dcContext = dcContext
        self.showArchive = showArchive
        dcContext.updateDeviceChats()
    }

    func chatDetailFor(indexPath: IndexPath) -> ChatListCellViewModelProtocol {
        return ChatListCellViewModel()
    }

    func chatSummaryFor(indexPath: IndexPath) -> DcLot{
        return chatList.getSummary(index: indexPath.row)
    }

    func deleteChat(chatId: Int) {
        self.dcContext.deleteChat(chatId: chatId)
        onChatListUpdate?()
    }

    func archieveChat(chatId: Int) {
        self.dcContext.archiveChat(chatId: chatId, archive: !self.showArchive)
        onChatListUpdate?()
    }





}