from PIL import Image
import xml.etree.ElementTree as ET
import os

class TileProcessor:
    def __init__(self, tile_size):
        self.tile_size = tile_size
        self.unique_tiles = {}  # Maps tile byte data to integer IDs
        self.tile_images = []   # Store images of unique tiles for tileset creation
        self.next_id = 0

    def get_tile(self, image, x, y):
        """Extract a tile from the specified position."""
        return image.crop((x * self.tile_size, y * self.tile_size,
                           (x + 1) * self.tile_size, (y + 1) * self.tile_size))

    def find_tile_in_set(self, tile):
        """Find the tile in the tileset and return its ID."""
        tile_bytes = tile.tobytes()
        if tile_bytes not in self.unique_tiles:
            self.unique_tiles[tile_bytes] = self.next_id
            self.tile_images.append(tile)  # Save the tile image for tileset creation
            self.next_id += 1
        return self.unique_tiles[tile_bytes]

    def create_tileset_image(self, output_dir):
        """Create a tileset image from unique tiles."""
        num_tiles = len(self.unique_tiles)
        tiles_per_row = int(num_tiles**0.5) + 1
        tileset_img = Image.new('RGBA', (tiles_per_row * self.tile_size, (num_tiles // tiles_per_row + 1) * self.tile_size))
        
        x = y = 0
        for tile_data, tile_id in self.unique_tiles.items():
            tile_img = Image.frombytes('RGBA', (self.tile_size, self.tile_size), tile_data)
            tileset_img.paste(tile_img, (x * self.tile_size, y * self.tile_size))
            x += 1
            if x >= tiles_per_row:
                x = 0
                y += 1
        
        tileset_path = os.path.join(output_dir, "JugdralTileset.png")
        tileset_img.save(tileset_path)
        return tileset_path, num_tiles, tiles_per_row

    def generate_tsx(self, tileset_path, num_tiles, tiles_per_row, output_dir):
        """Generate a TSX file for the created tileset."""
        tsx_tree = ET.Element("tileset", version="1.10", tiledversion="1.10.2", name="JugdralTileset",
                              tilewidth=str(self.tile_size), tileheight=str(self.tile_size),
                              tilecount=str(num_tiles), columns=str(tiles_per_row))
        ET.SubElement(tsx_tree, "image", source=os.path.relpath(tileset_path, output_dir),
                      width=str(tiles_per_row * self.tile_size), height=str((num_tiles // tiles_per_row + 1) * self.tile_size))

        tsx_path = os.path.join(output_dir, "JugdralTileset.tsx")
        tree = ET.ElementTree(tsx_tree)
        tree.write(tsx_path, encoding='utf-8', xml_declaration=True)
        print(f"Generated TSX file at: {tsx_path}")
        return tsx_path

    def process_images(self, tilemap_path, output_dir):
        """Process the tilemap and generate TMX and TSX files."""
        tilemap_img = Image.open(tilemap_path)
        tilemap_width = tilemap_img.width // self.tile_size
        tilemap_height = tilemap_img.height // self.tile_size

        # Create the tileset image and TSX file
        tileset_path, num_tiles, tiles_per_row = self.create_tileset_image(output_dir)
        tsx_path = self.generate_tsx(tileset_path, num_tiles, tiles_per_row, output_dir)

        # Create TMX structure with adjusted header and attributes
        map_element = ET.Element("map", version="1.10", tiledversion="1.10.2",
                                 orientation="orthogonal", renderorder="right-down",
                                 width=str(tilemap_width), height=str(tilemap_height),
                                 tilewidth=str(self.tile_size), tileheight=str(self.tile_size),
                                 infinite="0", nextlayerid="2", nextobjectid="1")
        ET.SubElement(map_element, "tileset", firstgid="1", source=os.path.basename(tsx_path))

        # Tile layer
        layer = ET.SubElement(map_element, "layer", id="1", name="Tile Layer 1",
                              width=str(tilemap_width), height=str(tilemap_height))
        data = ET.SubElement(layer, "data", encoding="csv")
        
        tilemap_data = []
        for y in range(tilemap_height):
            row_data = []
            for x in range(tilemap_width):
                tile = self.get_tile(tilemap_img, x, y)
                tile_id = self.find_tile_in_set(tile)
                row_data.append(str(tile_id + 1))  # Increment tile_id by 1 for Tiled compatibility
            tilemap_data.append(','.join(row_data) + ',')  # Append a comma at the end of each row

        data.text = '\n'.join(tilemap_data)

        # Save TMX file
        tmx_path = os.path.join(output_dir, "output_map.tmx")
        ET.ElementTree(map_element).write(tmx_path, encoding='utf-8', xml_declaration=True)
        print("Generated TMX at:", tmx_path)

# Usage
tile_size = 16  # Size of the tile in pixels
processor = TileProcessor(tile_size)
output_directory = os.path.dirname(os.path.abspath(__file__))  # Use the script's directory
tilemap_path = os.path.join(output_directory, "Jugdral Continental Project.png")
processor.process_images(tilemap_path, output_directory)