package xray

import (
	"github.com/InazumaV/V2bX/api/panel"
	"github.com/InazumaV/V2bX/common/format"
	"github.com/xtls/xray-core/common/protocol"
	"github.com/xtls/xray-core/common/serial"
	"github.com/xtls/xray-core/proxy/socks"
)

func buildSocksUsers(tag string, userInfo []panel.UserInfo) []*protocol.User {
	users := make([]*protocol.User, len(userInfo))
	for i := range userInfo {
		account := &socks.Account{
			Username: userInfo[i].Uuid,
			Password: userInfo[i].Uuid,
		}
		users[i] = &protocol.User{
			Level:   0,
			Email:   format.UserTag(tag, userInfo[i].Uuid),
			Account: serial.ToTypedMessage(account),
		}
	}
	return users
}
