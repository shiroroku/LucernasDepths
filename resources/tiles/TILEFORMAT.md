

```json
{
    "texture": { (required) 
        see texture formats below
    },
    "properties": { (optional) key-values that label how this tile can be interacted with.
        "solid": 1, if this tile should be collided with (if missing: no collision) 
        "toughness": 4, how many hits it takes to break this tile (if missing: this tile is unbreakable) 
        "break_tile": "stone" what tile to leave behind when it is broken (if missing: this is "dirt") 
    }
}
```

## Texture formats:
You can use either of these to render tile textures. bitmasked tiles convert a number to uv coords for textures which have multiple states.

Regular:
```json
{
    "texture": (required) {
        "atlas": "tiles/atlas.png", (required) the texture path
        "u": 0, (required) u and v for single static tiles
        "v": 0 (required)
    }
}
```

Bitmasked:
```json
{
    "texture": (required) {
        "atlas": "tiles/grass.png", (required) the texture path
        "bitmask": { (required)
            "mapping": "tiles/bitmask.floor.json", (required) json file which maps bits to uv coord
            "connects_to": [ (optional) tile id's which this bitmask can also connect to, will always connect to itself
                "dirt_wall",
                "stone_wall"
            ]
        }
    }
}
```