
# wolfram.sh

An [elementary cellular automaton](https://en.wikipedia.org/wiki/Elementary_cellular_automaton), based on the [Wolfram code](https://en.wikipedia.org/wiki/Wolfram_code) and implemented as a shell script.


## Table of Contents

1.  [Usage](#orgc3a7d26)
    1.  [As a terminal screensaver](#org8f7ec15)
2.  [Implementation](#org03949c6)
    1.  [Set the initial state](#org544af2c)
    2.  [Draw the current state](#org44ee361)
    3.  [Calculate cell values](#org3ae546c)
    4.  [Print new generations](#org227a091)
    5.  [Hide the cursor](#orgb84b07a)
3.  [Testing](#org9fef3f7)


<a id="orgc3a7d26"></a>

## Usage

```bash
./wolfram.sh [options]
```

-   **`-r`:** Which [rule](https://atlas.wolfram.com/01/01/rulelist.html) to use in the simulation. Defaults to choosing a random rule.
-   **`-w`:** The *width* of the simulation. Defaults to the number of columns in the terminal.
-   **`-g`:** The number of *generations* printed. Produces generations indefinitely by default.
-   **`-d`:** The *delay* before printing the next generation. Defaults to 0.1 seconds.

```bash
./wolfram.sh -r 30 -w 20 -g 10 -d 0
```

```
         █         
        ███        
       ██  █       
      ██ ████      
     ██  █   █     
    ██ ████ ███    
   ██  █    █  █   
  ██ ████  ██████  
 ██  █   ███     █ 
██ ████ ██  █   ███
```


<a id="org8f7ec15"></a>

### As a terminal screensaver

An interesting use of wolfram.sh is using it as a &ldquo;terminal screensaver&rdquo;.

An example using Alacritty opens the terminal in full screen mode, decreases the font size to increase the resolution, and disables the history. It then starts the program with a random pick from a selection of interesting rules:

```bash
alacritty --option font.size=2 \
          --option font.offset={x=3} \
          --option window.startup_mode='"Fullscreen"' \
          --option scrolling.history=0 \
          --command ./wolfram.sh -r $(shuf -e 30 45 60 90 110 150 -n 1)
```


<a id="org03949c6"></a>

## Implementation


<a id="org544af2c"></a>

### Set the initial state

The simulation emerges from an initial configuration of cells, which represent the first generation. Because the elementary cellular automaton is one-dimensional, its state can be represented as an array.

To generate an initial state, first determine the width of the simulation.

```bash
width=$(tput cols)
```

The width is set to the number of columns in the terminal window, but it can be configured with the `-w` flag.

```bash
while getopts "w:" flag; do
    case "$flag" in
        'w') width=$OPTARG;;
        *) exit
    esac
done
```

With the `width` set, generate the initial state by populating an array with zeroes. There is one live cell in the middle, represented by a 1 as the middle array element.

```bash
for ((i=0;i<=width-1;i++)); do
    state+=($((i == width/2)))
done
```

<a id="orge8378ec"></a> For example, running the code above in a terminal that&rsquo;s 9 cells wide produces an initial state with a width of 9 cells, with a single live cell in the middle:

```
(0 0 0 0 1 0 0 0 0)
```


<a id="org44ee361"></a>

### Draw the current state

The `draw` function prints the current state. Whenever it&rsquo;s called, it prints a line with either `█` or a space for each cell in the generation.

```bash
live="█"
dead=" "

draw() {
    local line=""
    for value in "$@"; do
          line+=$([ "$value" -eq 1 ] && echo "$live" || echo "$dead");
    done
    printf "%b" "${line}"
}
```

To draw the current `state`, pass it to the `draw()` function as an array.

```bash
draw "${state[@]}"
```

With the [initial state](#orge8378ec) state, the `draw()` function prints a single box in the middle of the screen to represent a single living cell.

```
░░░░█░░░░
```


<a id="org3ae546c"></a>

### Calculate cell values

To determine the next state of a cell, the program considers the cell&rsquo;s *neighborhood* in the previous generation. In the elementary cellular automaton, a cell&rsquo;s neighborhood consists of the cell in the same position in the previous generation, and the cell on the left and right of it.

```bash
neighborhood=$((state[i-1]))$((state[i]))$((${state[i+1]:-${state[0]}}))
```

When determining the state of the 5th cell in the second generation, the 4th, 5th and 6th cell in the previous generation are considered its neighborhood. For example, using the [initial state](#orge8378ec), calculating the neighborhood for the 5th element of the second generation:

    010

After finding the neighborhood, a *rule* is applied to decide what the next state should be.

There are [256 rules](https://plato.stanford.edu/entries/cellular-automata/supplement.html) in the elementary cellular automaton, each one derived from is binary representation. To extract the rule set, the rule number is converted to binary, split into an array, and finally reversed.

```bash
ruleset=(0 0 0 0 0 0 0 0)
for i in {0..7}; do
    ruleset[i]=$((rule % 2))
    rule=$((rule / 2))
done
```

For example, setting the `rule` variable to 30 produces the ruleset for [rule 30](https://en.wikipedia.org/wiki/Rule_30):

    (0 1 1 1 1 0 0 0)

Finally, with both the `ruleset` and `neighborhood` set, calculate the value for the new cell and add it to a new array named `new_state`. This is done by converting the neighborhood to a decimal value, and using that value as the index to look up the new value in `ruleset` array.

```bash
new_state+=("${ruleset[$((2#$neighborhood))]}")
```


<a id="org227a091"></a>

### Print new generations

Now that we have the logic to create a ruleset from a rule number and a way to calculate new generation cell values, the program can print new generations in a loop. For this, it needs to know which rule to use, and how many generations to print.

By default, one of the 256 rules is chosen at random. The `generations` variable is set to 0, which means the program keeps printing new generations until it&rsquo;s terminated manually. Finally, `delay` variable is set to 0.1, which determines how long the program sleeps between drawing generations.

```bash
rule=$((RANDOM % 256))
generations=0
delay=0.1
```

The `rule`, `generations` and `delay` variables are configurable, through the `-r`, `-g`, and `-d` command line options, respectively.

```bash
while getopts "d:g:r:w:" flag; do
    case "$flag" in
        'd') delay=$OPTARG;;
        'g') generations=$OPTARG;;
        'r') rule=$OPTARG;;
        'w') width=$OPTARG;;
        *) exit
    esac
done
```

With everything set up, the program can print generations by populating a `new_state` array, populating it, replacing the `state` variable, and then printing the new state with the `draw()` function in a loop.

```bash
count=1

while [ "$generations" = 0 ] || [ $count -lt "$generations" ]; do
    sleep "$delay"
    new_state=()

    for ((i=0;i<=width-1;i++)); do
        neighborhood=$((state[i-1]))$((state[i]))$((${state[i+1]:-${state[0]}}))
        new_state+=("${ruleset[$((2#$neighborhood))]}")
    done

    state=("${new_state[@]}")

    printf "\n"
    draw "${state[@]}"

    ((count++))
done
```


<a id="orgb84b07a"></a>

### Hide the cursor

To prevent flickering while drawing, the program hides the cursor before printing the first generation. Then, right before exiting, the cursor is set back to normal.

```bash
hide-cursor() {
    tput civis
}

show-cursor() {
    tput cnorm
}

trap show-cursor EXIT
hide-cursor
```


<a id="org9fef3f7"></a>

## Testing

The program is tested with [bats](https://github.com/bats-core/bats-core), a testing framework for bash. To run the tests, evaluate `test.bats`.

```bash
./test.bats
```