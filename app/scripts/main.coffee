roundTimestamp = (timestamp) ->
  ts = new Date(parseInt(timestamp) * 1000)
  ts.setSeconds 0
  ts.setMinutes 0
  ts.setHours 0
  ts.getTime()

createGraph = (channels) ->
  nv.addGraph () ->
    chart = nv.models.lineChart().useInteractiveGuideline(true)
    chart.xAxis.tickFormat (d) ->
      d3.time.format('%b %d')(new Date(d))
    chart.xScale(d3.time.scale())
    chart.yAxis.axisLabel('Messages per day')
    d3.select('#chart svg')
      .datum(channels)
      .transition().duration(500)
      .call(chart)
    nv.utils.windowResize(chart.update)
    chart

getSlackData = (slackAPIToken) ->
  $.ajax("https://slack.com/api/channels.list?token=#{slackAPIToken}").done (channelList) ->
    channels = []
    deferreds = []

    processChannel = (channel) ->
      $.ajax("https://slack.com/api/channels.history?token=#{slackAPIToken}&channel=#{channel.id}&count=1000").done (channelHistory) ->
        if (!channelHistory.messages.length)
          return

        startTimestamp = roundTimestamp(channelHistory.messages[channelHistory.messages.length - 1].ts)
        endTimestamp = roundTimestamp(channelHistory.messages[0].ts)

        messages = {}

        for message in channelHistory.messages
          timestamp = roundTimestamp(message.ts);
          
          if (messages[timestamp])
            messages[timestamp]++
          else
            messages[timestamp] = 1

        values = []

        for ts in [startTimestamp..endTimestamp] by 86400000
          values.push
            x: ts
            y: messages[ts] || 0

        channels.push
          values: values
          key: channel.name
          area: true

    for channel in channelList.channels
      deferreds.push(processChannel(channel))

    $.when.apply(this, deferreds).then(() -> createGraph(channels))

$('#button').click (e) ->
  e.preventDefault()
  token = $('#token').val().trim()
  return if !token
  getSlackData token
  $('#form').fadeOut(1000)
