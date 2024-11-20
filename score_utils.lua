-- score_utils.lua

-- Function to update messages displayed on the screen
function update_messages(messages)
    -- Assuming you have a setMessage function for updating messages
    -- Here, we just overwrite the previous messages with new ones
    for i, msg in ipairs(messages) do
        ac.setMessage(i, msg.text)  -- Use ac.setMessage to display the messages
    end
end

-- Function to sort scores (for example, sorting a table of scores)
function sort_scores(scores)
    -- Sort the scores in descending order
    table.sort(scores, function(a, b) return a.score > b.score end)
    return scores
end

-- Function to calculate the highest score
function get_highest_score(scores)
    local highest = 0
    for _, entry in ipairs(scores) do
        if entry.score > highest then
            highest = entry.score
        end
    end
    return highest
end

-- Function to filter scores based on a condition
function filter_scores(scores, condition)
    local filtered = {}
    for _, entry in ipairs(scores) do
        if condition(entry) then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

-- Function to calculate a score multiplier
function calculate_multiplier(baseScore, multiplier)
    return baseScore * multiplier
end

return {
    update_messages = update_messages,
    sort_scores = sort_scores,
    get_highest_score = get_highest_score,
    filter_scores = filter_scores,
    calculate_multiplier = calculate_multiplier
}