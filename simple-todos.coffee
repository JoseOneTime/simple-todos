Tasks = new Mongo.Collection 'tasks'

if Meteor.isServer
  Meteor.publish 'tasks', ->
    Tasks.find
      $or: [
        {private: {$ne: true}}
        {owner: @userId}
      ]

if Meteor.isClient
  Meteor.subscribe 'tasks'

  Template.body.helpers
    tasks: ->
      if Session.get 'hideCompleted'
        Tasks.find {checked: {$ne: true}}, {sort: {createdAt: -1}}
      else
        Tasks.find {}, {sort: {createdAt: -1}}

    hideCompleted: -> Session.get 'hideCompleted'

    incompleteCount: ->
      Tasks.find {checked: {$ne: true}}
        .count()

  Template.body.events
    'submit .new-task': (evt) ->
      evt.preventDefault()
      Meteor.call 'addTask', evt.target.text.value
      evt.target.text.value = ''

    'change .hide-completed input': (evt) ->
      Session.set 'hideCompleted', evt.target.checked


  Template.task.helpers
    isOwner: -> @owner is Meteor.userId()

  Template.task.events
    'click .toggle-checked': ->
      Meteor.call 'setChecked', @_id, not @checked

    'click .delete': -> Meteor.call 'deleteTask', @_id

    'click .toggle-private': ->
      Meteor.call 'setPrivate', @_id, not @private

  Accounts.ui.config passwordSignupFields: 'USERNAME_ONLY'

Meteor.methods
  addTask: (text) ->
    throw new Meteor.Error 'not-authorized' unless Meteor.userId()
    Tasks.insert {
      text
      createdAt: new Date()
      owner: Meteor.userId()
      username: Meteor.user().username
    }

  deleteTask: (taskId) ->
    task = Tasks.findOne taskId

    if task.private and task.owner isnt Meteor.userId()
      throw new Meteor.Error 'not-authorized'

    Tasks.remove taskId

  setChecked: (taskId, checked) ->
    task = Tasks.findOne taskId

    if task.private and task.owner isnt Meteor.userId()
      throw new Meteor.Error 'not-authorized'

    Tasks.update taskId, {$set: {checked}}

  setPrivate: (taskId, private) ->
    task = Tasks.findOne taskId

    if task.private and task.owner isnt Meteor.userId()
      throw new Meteor.Error 'not-authorized'

    Tasks.update taskId, {$set: {private}}
