from __future__ import annotations

import logging

from PySide6.QtCore import QIODevice, QObject, Signal
from PySide6.QtNetwork import QLocalServer, QLocalSocket

logger = logging.getLogger("flowtype.single_instance")


class SingleInstanceManager(QObject):
    activationRequested = Signal(str)

    def __init__(self, app_id: str = "AntiGravity.FlowType", parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._app_id = app_id
        self._server = QLocalServer(self)
        self._server.newConnection.connect(self._handle_new_connection)
        self._owns_server = False

    def try_acquire(self, message: str = "show") -> bool:
        if self._notify_existing(message):
            return False

        QLocalServer.removeServer(self._app_id)
        if self._server.listen(self._app_id):
            self._owns_server = True
            return True

        if self._notify_existing(message):
            return False

        raise RuntimeError(f"Unable to create single-instance server for {self._app_id}")

    def release(self) -> None:
        if not self._owns_server:
            return
        self._server.close()
        QLocalServer.removeServer(self._app_id)
        self._owns_server = False

    def _notify_existing(self, message: str) -> bool:
        socket = QLocalSocket(self)
        socket.connectToServer(self._app_id, QIODevice.OpenModeFlag.WriteOnly)
        if not socket.waitForConnected(200):
            socket.abort()
            socket.deleteLater()
            return False

        payload = (message.strip() or "show").encode("utf-8")
        socket.write(payload)
        socket.flush()
        socket.waitForBytesWritten(200)
        socket.disconnectFromServer()
        socket.deleteLater()
        return True

    def _handle_new_connection(self) -> None:
        while self._server.hasPendingConnections():
            socket = self._server.nextPendingConnection()
            if socket is None:
                continue
            socket.readyRead.connect(lambda s=socket: self._read_message(s))
            socket.disconnected.connect(socket.deleteLater)
            self._read_message(socket)

    def _read_message(self, socket: QLocalSocket) -> None:
        payload = bytes(socket.readAll()).decode("utf-8", errors="ignore").strip() or "show"
        self.activationRequested.emit(payload)
