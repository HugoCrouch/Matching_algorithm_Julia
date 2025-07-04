# Flexible Deferred Acceptance Algorithm in Julia
# multiple to one
# acceptor has its own region and target limit 
# each acceptor is assigned priority in its region

function FDA(props, accs, prop_prefs, acc_prefs, acc_cap, regions, acc_region, target_lim, reg_prior)
    prop_prefs_copy = deepcopy(prop_prefs)
    free_props = Set(props)
    acc_matches = Dict(a => [] for a in accs) #keep -> formal matching
    prop_matches = Dict(a => [] for a in props)
    acc_matches["outside"] = []
    prop_matches["outside"] = []
    acc_applylist = deepcopy(acc_matches)
    acc_applylist_copy = Dict(acc => "" for acc in accs)

    region_lim = Dict(reg => 0 for reg in regions)
    for acc in accs
        reg = acc_region[acc]
        region_lim[reg] += target_lim[acc]
    end

    algo_lim = 5000
    count = 1

    while !isempty(free_props) && count < algo_lim
        wait_list = Dict(acc => [] for acc in accs)
        current = Dict(reg => 0 for reg in regions)
        print(count, ": free:", free_props, "\n")
        
        for prop in free_props
            flag = false
            apply = first(prop_prefs_copy[prop])
            for j in acc_prefs[apply[1]]
                if j[1] == prop
                    flag = true
                    push!(acc_applylist[apply[1]], j)
                end
            end
            prop_prefs_copy[prop] = setdiff(prop_prefs_copy[prop], [apply])
            if !flag
                if isempty(prop_prefs_copy[prop])
                    push!(prop_matches["outside"], prop) # matches outside option
                    delete!(free_props, prop)
                end
            end
        end

        for acc in accs
            if acc_applylist[acc] !== acc_applylist_copy[acc]
                sort!(acc_applylist[acc], by = x -> x[2])

                k = min(acc_cap[acc], target_lim[acc], length(acc_applylist[acc]))
                acc_matches[acc] = acc_applylist[acc][1:k]

                current[acc_region[acc]] += length(acc_matches[acc])

                if acc_matches[acc] == []
                    acc_matches[acc] = ("outside",1)
                end
                if k < length(acc_applylist[acc])
                    wait_list[acc] = acc_applylist[acc][k+1:end]
                end
            end
        end
        acc_applylist_copy = deepcopy(acc_applylist)

        for reg in regions
            while current[reg] < region_lim[reg] +1
                pick = false
                for acc_p in reg_prior[reg]
                    if current[reg] == region_lim[reg]
                        break
                    end
                    if length(acc_matches[acc_p]) < acc_cap[acc_p] && !isempty(wait_list[acc_p])
                        push!(acc_matches[acc_p], first(wait_list[acc_p]))
                        print(acc_p, " wait list : ", wait_list, "\n")
                        print(acc_p, " accepted ", first(wait_list[acc_p]), "\n")
                        wait_list[acc_p] = setdiff!(wait_list[acc_p], [first(wait_list[acc_p])])
                        current[reg] += 1
                        pick = true
                    end
                end
                if !pick
                    break
                end
            end
        end
        for acc in accs
            for kept in acc_matches[acc]
                delete!(free_props, kept[1])
            end
            if !isempty(wait_list[acc])
                #print(wait_list[acc], " is rejected by ", acc, "\n")
            end
            for rejected in wait_list[acc]
                if isempty(prop_prefs_copy[rejected[1]])
                    push!(prop_matches["outside"], rejected[1])
                    delete!(free_props, rejected[1])
                else
                    push!(free_props, rejected[1])
                end
            end
            acc_applylist[acc] = deepcopy(acc_matches[acc])
        end
        count += 1
        if count == algo_lim
            print("reached algo_lim")
        end
    end

    for acc in accs
        acc_matches[acc] = [k[1] for k in acc_matches[acc]]
        for i in acc_matches[acc]
            push!(prop_matches[i], acc)
        end
    end
    return prop_matches, acc_matches
end

# Example usage
props = ["A", "B", "C", "D", "E", "F"]
accs = ["X", "Y", "Z"]
prop_prefs = Dict("A" => [("X",1), ("Y",2), ("Z",3)],
                      "B" => [("Y",1), ("X",2), ("Z",3)],
                      "C" => [("X",1), ("Z",2), ("Y",3)],
                      "D" => [("Z",1), ("Y",2), ("X",3)],
                      "E" => [("Y",), ("X",2)],
                      "F" => [("X",1), ("Y",2)])
acc_prefs = Dict("X" => [("B",1), ("A",2), ("C",3), ("E",4), ("F",5)], 
                 "Y" => [("A",1), ("C",2), ("B",3), ("D",4), ("F",5), ("E",6)], 
                 "Z" => [("D",1), ("A",2), ("B",3), ("C",4), ("E", 5)])
acc_cap = Dict("X" => 2, "Y" => 2, "Z" => 2)
regions = ["N", "S"]
acc_region = Dict("X" => "N", "Y" => "N", "Z" => "S")
target_lim = Dict("X" => 2, "Y" => 1, "Z" => 2) #must be smaller than or equal to acc_cap
reg_prior = Dict("N" => ["X", "Y"], "S" => ["Z"])



props = ["$i" for i in 1:10]
accs = ["A", "B"]

prop_prefs = Dict(i in 1:3 ? "$i" => [("A",1)] : "$i" => [("B",1)] for i in 1:10)
acc_prefs = Dict("A" => [("$i", i) for i in 1:10],
                    "B" => [("$i", i) for i in 1:10])
acc_cap = Dict("A" => 10, "B" => 10)
regions = ["N"]
acc_region = Dict("A" => "N", "B" => "N")
target_lim = Dict("A" => 5, "B" => 5) #must be smaller than or equal to acc_cap
reg_prior = Dict("N" => ["A", "B"])

matches = FDA(props, accs, prop_prefs, acc_prefs, acc_cap, regions, acc_region, target_lim, reg_prior)
println(matches)
