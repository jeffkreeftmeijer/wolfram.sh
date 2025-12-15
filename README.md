- [Usage](#orgebbc4ea)
- [Implementation](#orgda39cff)
  - [Set the initial state](#orgf0a1115)
  - [Draw the current state](#orge2835c4)
  - [Calculate cell values](#orgab8583d)
  - [Print new generations](#orgdb11da1)
  - [Hide the cursor](#org57085e3)
- [Testing](#org17fb00b)


<a id="orgebbc4ea"></a>

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


<a id="orgda39cff"></a>

## Implementation


<a id="orgf0a1115"></a>

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

<a id="org053b775"></a> For example, running the code above in a terminal that's 9 cells wide produces an initial state with a width of 9 cells, with a single live cell in the middle:

```
(0 0 0 0 1 0 0 0 0)
```


<a id="orge2835c4"></a>

### Draw the current state

The `draw` function prints the current state. Whenever it's called, it prints a line with either `█` or a space for each cell in the generation.

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

With the [initial state](#org053b775) state, the `draw()` function prints a single box in the middle of the screen to represent a single living cell.

```
░░░░█░░░░
```


<a id="orgab8583d"></a>

### Calculate cell values

To determine the next state of a cell, the program considers the cell's *neighborhood* in the previous generation. In the elementary cellular automaton, a cell's neighborhood consists of the cell in the same position in the previous generation, and the cell on the left and right of it.

```bash
neighborhood=$((state[i-1]))$((state[i]))$((${state[i+1]:-${state[0]}}))
```

When determining the state of the 5th cell in the second generation, the 4th, 5th and 6th cell in the previous generation are considered its neighborhood. For example, using the [initial state](#org053b775), calculating the neighborhood for the 5th element of the second generation:

    010

After finding the neighborhood, a *rule* is applied to decide what the next state should be.

There are 256 rules in the elementary cellular automaton, each one derived from is binary representation. To extract the rule set, the rule number is converted to binary, split into an array, and finally reversed.

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


<a id="orgdb11da1"></a>

### Print new generations

Now that we have the logic to create a ruleset from a rule number and a way to calculate new generation cell values, the program can print new generations in a loop. For this, it needs to know which rule to use, and how many generations to print.

By default, one of the 256 rules is chosen at random. The `generations` variable is set to 0, which means the program keeps printing new generations until it's terminated manually. Finally, `delay` variable is set to 0.1, which determines how long the program sleeps between drawing generations.

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


<a id="org57085e3"></a>

### Hide the cursor

To prevent flickering while drawing, the program hides the cursor before printing the first generation. Then, right before exiting, the cursor is set back to normal.

```bash
function hide-cursor() {
    tput civis
}

function show-cursor() {
    tput cnorm
}

trap show-cursor EXIT
hide-cursor
```


<a id="org17fb00b"></a>

## Testing

The program is tested with [bats](https://github.com/bats-core/bats-core), a testing framework for bash. To run the tests, evaluate `test.bats`.

```bash
./test.bats
```