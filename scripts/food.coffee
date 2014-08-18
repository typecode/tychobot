# Description:
#   Helps you satisfy your hunger
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot food - List all known restaurants
#   hubot food <name|alias> - Show info for a restaurant given it's name or alias
#   hubot food add "<name>" <menu_url> - Add a restaurant
#   hubot food remove "<name>" - Remove a restaurant
#   hubot food alias "<name>" <alias> - Alias a restaurant with <alias> (alphanumeric)
#   hubot food unalias <alias> - Unalias a restaurant with <alias>
#
# Author:
#   mattbriancon

send_force_required = (msg, extra) ->
    extra = if extra then '\n\n' + extra else ''

    nopes = [
        'NOOOOOOOOOOOOOOOOOOOOPE!',
        'Nope nope nope.',
        'Yeah, that\'s a whole lot of nope.',
    ]

    msg.send("""
        #{msg.random(nopes)} You can't make me!#{extra}

        (Add 'force' to the end of the command if you're sure you want to do this.)
    """)

init_brain = ->
    console.log 'init brain'
    robot.brain.data.food ?= {}
    robot.brain.data.food.restaurants ?= {}
    robot.brain.data.food.aliases ?= {}

blacklist = [
    'add',
    'remove',
    'alias',
    'unalias',
    'init',
]

module.exports = (robot) ->
    robot.on 'running', ->
        init_brain()

    robot.respond /food init$/, (msg) ->
        init_brain()

    robot.respond /food add "([\w-' ]+)" (https?:\/\/[^\s]+)( force)?/, (msg) ->
        name = msg.match[1]
        menu = msg.match[2]
        force = msg.match[3]?

        if name in blacklist
            msg.send("#{name} is a command and can't be used as a name.")
            return

        if name of robot.brain.data.food.restaurants and not force
            send_force_required(msg, "I already know about #{name}.")
            return

        robot.brain.data.food.restaurants[name] = 'menu': menu

        saved = [
            "I'll always remember #{name} as the place where I first fell in love with you!",
            "I can't wait to eat at #{name}!",
            "Does #{name} make artisanal dog food?",
            "BARK BARK BARK #{name} BARK BARK BARK",
        ]
        msg.send(msg.random(saved))

    robot.respond /food remove "([\w-' ]+)"( force)?/, (msg) ->
        name = msg.match[1]
        force = msg.match[2]?

        if not force
            send_force_required(msg)
            return

        delete robot.brain.data.food.restaurants[name]

        msg.send "Forgot all about #{name}."

    robot.respond /food$/i, (msg) ->
        reverse_aliases = {}
        for alias, name of robot.brain.data.food.aliases
            reverse_aliases[name] ||= []
            reverse_aliases[name].push(alias)

        pairs = []
        for name, props of robot.brain.data.food.restaurants
            aliases = if name of reverse_aliases then " (aliases: #{reverse_aliases[name].join(', ')})" else ''
            pairs.push("#{name}: #{props.menu}\n\t#{aliases}")

        msg.send("""
            Here are all the restaurants I know about:

            #{pairs.sort().join('\n')}
        """)

    robot.respond /food alias "([\w-' ]+)" (\w+)( force)?/, (msg) ->
        name = msg.match[1]
        alias = msg.match[2]
        force = msg.match[3]?

        # check that restaurant exists
        if name not of robot.brain.data.food.restaurants
            msg.send("I don't know about #{name} yet.")
            return

        # check that alias isn't a command
        if alias in blacklist
            msg.send("#{alias} is a command and can't be used as a alias.")
            return

        # check that alias doesn't already exist and force wasn't used
        if alias of robot.brain.data.food.aliases and not force
            send_force_required(msg, "#{alias} is already aliased to #{robot.brain.data.food.alias[alias]}.")
            return

        robot.brain.data.food.aliases[alias] = name

    robot.respond /food unalias (\w+)/, (msg) ->
        alias = msg.match[1]

        if alias of robot.brain.data.food.aliases
            delete robot.brain.data.food.aliases[alias]

    robot.respond /food (.*)/, (msg) ->
        name = msg.match[1]

        # ignore command names
        if name in blacklist
            return

        restaurants = robot.brain.data.food.restaurants

        # first try full names
        if name of restaurants
            msg.send("#{name}: #{restaurants[name].menu}.")
            return

        aliases = robot.brain.data.food.aliases

        # then try aliases
        if name of aliases
            name = aliases[name]
            msg.send("#{name}: #{restaurants[name].menu}.")
            return
