### 1. Core Classes

#### `PhonemeInventory`

- **Purpose**: Manage allowed phonemes and their features
    
- **Attributes**:
    
  - `consonants: Set[str]`
        
  - `vowels: Set[str]`
        
  - `features: Dict[str, Set[str]]` (e.g., {"plosive": ["p", "t"], "front": ["i", "e"]})
        
- **Methods**:
    
  - `add_phoneme()`, `validate_cluster()`
        

#### `RomanizationMap`

-   **Purpose**: Convert phonemes to romanized text
    
- **Attributes**:
    
  - `mapping: Dict[str, str]` (phoneme → romanization)
        
  - `special_rules: Dict[Tuple, str]` (context-specific mappings)
        
- **Methods**:
    
  - `romanize(phonemes: List[str]) -> str`
        

#### `ClusterConfiguration`

-   **Purpose**: Define legal phoneme clusters
    
- **Attributes**:
    
  - `onsets: Dict[str, List[Tuple]]` (e.g., {"simple": [("C",)], "complex": [("C", "C")]})
        
  - `codas: Dict[str, List[Tuple]]`
        
  - `weights: Dict[str, float]` (cluster type weights)
        
- **Methods**:
    
  - `get_cluster(type: str, position: str) -> List[Tuple]`
        

#### `SyllableTemplate`

-   **Purpose**: Define syllable structures
    
- **Attributes**:
    
  - `patterns: List[Tuple[str]]` (e.g., [("O", "N"), ("O", "N", "C")])
        
  - `component_map: Dict[str, str]` (e.g., {"O": "onset", "N": "nucleus"})
        
- **Methods**:
    
  - `validate_pattern()`
        

### 2. Generator Core

#### `SyllableGenerator`

-   **Purpose**: Generate single syllables
    
-   **Dependencies**: `PhonemeInventory`, `ClusterConfiguration`, `SyllableTemplate`
    
- **Methods**:
    
  - `generate(weights: bool = True) -> List[str]`:
        
```python
def generate(self):
    pattern = self.weighted_pattern_choice()
    components = []
    for symbol in pattern:
        component_type = self.template.component_map[symbol]
        cluster_type = self.select_cluster_type(component_type)
        phonemes = self.select_phonemes(component_type, cluster_type)
        components.extend(phonemes)
    return components
```
        

#### `WordGenerator`

-   **Purpose**: Generate multi-syllable words
    
- **Attributes**:
    
    -   `syllable_count: Tuple[int, int]` (min/max syllables)
        
    -   `syllable_joiner: str` (e.g., "" or ".")
        
- **Methods**:
    
  - `generate() -> str`:
        
```python
def generate(self):
    syllables = [self.syllable_gen.generate() for _ in range(self.random_syllable_count)]
    phonemes = [p for syl in syllables for p in syl]
    return self.romanizer.romanize(phonemes)
```
        

### 3. Configuration System

#### `GeneratorConfig`

-   **Purpose**: Central configuration container
    
- **Attributes**:
    
  - `features: Dict[str, bool]` (e.g., {"allow_codas": True})
        
  - `weights: Dict[str, Dict]` (multi-level weighting)
        
- **Methods**:
    
  - `set_feature(feature: str, enabled: bool)`
        
  - `update_weights(new_weights: Dict)`
        

### 4. Weighting System

- **Implement weighted choices**:
    
```python
def weighted_choice(items, weights):
    return random.choices(items, weights=weights)[0]
```
    
- **Weighting hierarchy**:
    
  1. Phoneme frequency weights
        
  2. Cluster type weights
        
  3. Syllable pattern weights
        

### 5. Feature Toggles

- **Dynamic runtime control**:
    
```python
class FeatureToggle:
    def __init__(self, config):
        self.config = config
    
    def filter_phonemes(self, phonemes, phoneme_type):
        if not self.config["allow_" + phoneme_type + "_clusters"]:
            return [p for p in phonemes if len(p) == 1]
        return phonemes
```
    

### 6. Output Pipeline

1. Generate phoneme sequence
    
2. Apply context-sensitive romanization rules
    
3. Post-process concatenated string:
    
```python
def romanize(phonemes):
    output = ""
    for i, p in enumerate(phonemes):
        # Apply context rules
        if i > 0 and phonemes[i-1] in vowels and p in nasals:
            output += special_map.get(p, p)
        else:
            output += self.mapping.get(p, p)
    return output
```
    

### Usage Example

```python
# Configuration
config = GeneratorConfig()
config.set_feature("complex_onsets", True)

phonemes = PhonemeInventory(consonants=["p", "t", "k", "s"], vowels=["a", "e"])
roman_map = RomanizationMap({"p": "p", "t": "t", "k": "k", "s": "s", "a": "a", "e": "e"})

clusters = ClusterConfiguration()
clusters.add_onset("simple", [("C",)])
clusters.add_onset("complex", [("C", "C")], weight=0.3)

templates = SyllableTemplate([("O", "N"), ("O", "N", "C")])

# Generator setup
syll_gen = SyllableGenerator(phonemes, clusters, templates, config)
word_gen = WordGenerator(syll_gen, roman_map, syllable_count=(1, 3))

# Generate word
print(word_gen.generate())  # e.g., "sakata"
```

### Key Design Features

1. **Extensibility**:
    
   - Add new phoneme features without breaking existing code
        
   - Implement `ClusterStrategy` interface for custom cluster generation
        
2. **Dynamic Control**:
    
```python
# Runtime modification
config.set_feature("allow_codas", False)
word_gen.update_weights({"syllable_pattern": {("O","N"): 0.8}})
```
    
3. **Validation**:
    
   - Automatic pattern validation
        
   - Phoneme existence checks in clusters
        
   - Weight normalization
        
4. **Context Handling**:
    
   - Position-aware romanization
        
   - Cluster boundary detection
        

This architecture provides granular control while maintaining flexibility. The separation of concerns allows language enthusiasts to:

- Define complex phonotactic rules
    
- Model rare linguistic phenomena
    
- Tune frequency distributions
    
- Handle edge cases through special rules
    
- Extend components via inheritance
    

For advanced usage, consider adding:

- Sandhi rules for syllable boundaries
    
- Stress/intonation patterns
    
- Morphological constraints
    
- Diacritic handling in romanization
    
- Historical sound change rules