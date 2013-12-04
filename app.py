
import re

from twisted.internet import protocol, reactor, ssl, defer
from twisted.words.protocols import irc


def parse_nickname(user):
    return user.split('!')[0].lstrip('@')

RESTAURANTS = {
    'tenda': ('Tenda Asian Bistro', 'http://www.seamless.com/food-delivery/tenda-asian-bistro-brooklyn.7457.r#menu-tab'),
    'tutt': ('Tutt Cafe', 'http://www.tuttcafe.com/menu.html'),
    'indian': ('Curry Heights', 'http://www.seamless.com/food-delivery/curry-heights-brooklyn.7023.r#menu-tab'),
    'pizza': ('Il Porto', 'http://www.seamless.com/food-delivery/il-porto-brooklyn.6217.r#menu-tab'),
    'doubles': ('A&A Bake & Doubles Shop', 'http://www.yelp.com/biz/a-and-a-bake-and-doubles-shop-brooklyn'),
}

RESTAURANT_RE = re.compile(r'({})'.format('|'.join(RESTAURANTS)))


class TychoBot(irc.IRCClient):
    nickname = 'tycho'
    username = 'tycho'
    password = 'tycho'

    channels = [
        '#lobby',
        '#architizer',
        '#bot-testing'
        '#typecode',
        '#designtrust',
    ]

    admins = ['matt']

    _names_callbacks = {}

    def connectionMade(self):
        irc.IRCClient.connectionMade(self)
        print('Connection Made')

    def connectionLost(self, reason):
        irc.IRCClient.connectionLost(self, reason)
        print('Connection Lost', reason)

    def signedOn(self):
        print('signedOn')
        for channel in self.channels:
            self.join(channel)

    def joined(self, channel):
        # print('joined', channel)
        pass

    def privmsg(self, user, channel, message):
        # print(user, channel, message)
        user = parse_nickname(user)

        if channel == self.nickname:
            self.handle_whisper(user, message)
            return

        if message.startswith(self.nickname):
            self.handle_command(user, channel, message)
            return

        self.handle_general(user, channel, message)

    def handle_whisper(self, user, message):
        # print('handle_whisper')
        self.msg(user, 'I like to whisper too!')

    def handle_command(self, user, channel, message):
        print('handle_command')

    def handle_general(self, users, channel, message):
        # print('handle_general')
        hay = r'(hey |hay )?(guys|guise)'
        if re.match(hay, message):
            self.ping_channel(channel)

        for name in RESTAURANT_RE.findall(message.lower()):
            self.say(channel, '{}: {}'.format(*RESTAURANTS[name]))

    def ping_channel(self, channel):
        print('ping_channel')

        def got_names(name_list):
            name_list = [parse_nickname(nick) for nick in name_list]
            name_list.remove(self.nickname)

            self.say(channel, ' '.join(name_list))

        self.names(channel).addCallback(got_names)

    def names(self, channel):
        channel = channel.lower()
        d = defer.Deferred()
        if channel not in self._names_callbacks:
            self._names_callbacks[channel] = ([], [])

        self._names_callbacks[channel][0].append(d)
        self.sendLine("NAMES %s" % channel)
        return d

    def irc_RPL_NAMREPLY(self, prefix, params):
        channel = params[2].lower()
        nicklist = params[3].split(' ')

        if channel not in self._names_callbacks:
            return

        n = self._names_callbacks[channel][1]
        n += nicklist

    def irc_RPL_ENDOFNAMES(self, prefix, params):
        channel = params[1].lower()
        if channel not in self._names_callbacks:
            return

        callbacks, namelist = self._names_callbacks[channel]

        for cb in callbacks:
            cb.callback(namelist)

        del self._names_callbacks[channel]


class TychoBotFactory(protocol.ClientFactory):
    def __init__(self):
        pass

    def buildProtocol(self, addr):
        tb = TychoBot()
        return tb

    def clientConnectionLost(self, connector, reason):
        print('Connection Lost', reason)
        # connector.connect()

    def clientConnectionFailed(self, connector, reason):
        print('Connection Failed', reason)
        reactor.stop()


if __name__ == '__main__':
    bot = TychoBotFactory()

    context = ssl.ClientContextFactory()
    reactor.connectSSL('portal.typeco.de', 6664, bot, context)
    reactor.run()
