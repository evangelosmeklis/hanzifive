#!/usr/bin/env python3
"""
Generate HSK JSON files with pinyin and meanings from CC-CEDICT dictionary.
Output format matches the app's ModernWordPayload structure.
"""

import xlrd
import json
import re
from pypinyin import pinyin, Style

def load_cedict(filepath):
    """Load CC-CEDICT dictionary into a lookup table."""
    dictionary = {}
    
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            # Skip comments
            if line.startswith('#'):
                continue
            
            # Parse line format: Traditional Simplified [pinyin] /definition1/definition2/.../
            match = re.match(r'^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+)/$', line.strip())
            if match:
                traditional = match.group(1)
                simplified = match.group(2)
                pinyin_str = match.group(3)
                definitions = match.group(4).split('/')
                
                # Clean up definitions - remove CL: classifiers and other metadata
                clean_definitions = []
                for d in definitions:
                    d = d.strip()
                    if d and not d.startswith('CL:') and not d.startswith('see '):
                        clean_definitions.append(d)
                
                # Store by simplified character
                if simplified not in dictionary:
                    dictionary[simplified] = []
                
                dictionary[simplified].append({
                    'traditional': traditional,
                    'pinyin': pinyin_str,
                    'meanings': clean_definitions
                })
    
    return dictionary

def convert_pinyin_to_tone_marks(pinyin_str):
    """Convert numeric pinyin (like 'ai4') to tone marks (like 'ài')."""
    tone_marks = {
        'a': ['ā', 'á', 'ǎ', 'à', 'a'],
        'e': ['ē', 'é', 'ě', 'è', 'e'],
        'i': ['ī', 'í', 'ǐ', 'ì', 'i'],
        'o': ['ō', 'ó', 'ǒ', 'ò', 'o'],
        'u': ['ū', 'ú', 'ǔ', 'ù', 'u'],
        'ü': ['ǖ', 'ǘ', 'ǚ', 'ǜ', 'ü'],
        'v': ['ǖ', 'ǘ', 'ǚ', 'ǜ', 'ü'],  # v is sometimes used for ü
    }
    
    def convert_syllable(syllable):
        # Check if ends with a tone number
        if not syllable or not syllable[-1].isdigit():
            return syllable
        
        tone = int(syllable[-1])
        if tone < 1 or tone > 5:
            return syllable
        
        syllable = syllable[:-1]  # Remove tone number
        
        # Handle special case: lv, nv -> lü, nü
        syllable = syllable.replace('v', 'ü')
        
        # Find the vowel to add tone mark to
        # Priority: a, e, ou, then last vowel
        for vowel in ['a', 'e']:
            if vowel in syllable:
                return syllable.replace(vowel, tone_marks[vowel][tone-1], 1)
        
        if 'ou' in syllable:
            return syllable.replace('o', tone_marks['o'][tone-1], 1)
        
        # Find last vowel
        for i in range(len(syllable) - 1, -1, -1):
            if syllable[i] in tone_marks:
                return syllable[:i] + tone_marks[syllable[i]][tone-1] + syllable[i+1:]
        
        return syllable
    
    # Split by spaces and convert each syllable
    syllables = pinyin_str.split()
    converted = [convert_syllable(s) for s in syllables]
    return ' '.join(converted)

def get_pinyin_with_tones(word):
    """Get pinyin with tone marks using pypinyin."""
    result = pinyin(word, style=Style.TONE)
    return ' '.join([p[0] for p in result])

def clean_word(word):
    """Clean up word by removing annotations in parentheses."""
    # Remove Chinese annotations like （叹词）, （形容词）, etc.
    word = re.sub(r'（[^）]+）', '', word)
    # Remove English annotations
    word = re.sub(r'\([^)]+\)', '', word)
    # Remove extra whitespace
    word = word.strip()
    return word

def extract_hsk_words(excel_path, sheet_name):
    """Extract words from a specific HSK level sheet."""
    workbook = xlrd.open_workbook(excel_path)
    sheet = workbook.sheet_by_name(sheet_name)
    
    words = []
    for row_idx in range(sheet.nrows):
        cell_value = sheet.cell_value(row_idx, 0)
        # Clean up the word (remove trailing spaces and annotations)
        word = clean_word(cell_value)
        if word and word not in words:  # Avoid duplicates
            words.append(word)
    
    return words

def is_surname_or_proper_noun(meanings):
    """Check if the meanings indicate this is primarily a surname or proper noun."""
    if not meanings:
        return False
    first_meaning = meanings[0].lower()
    return first_meaning.startswith('surname ') or first_meaning.startswith('abbr. for')

def get_best_entry(entries):
    """Get the best dictionary entry, preferring common words over surnames/proper nouns."""
    if not entries:
        return None
    
    # First pass: look for entries that are NOT surnames/proper nouns
    for entry in entries:
        if not is_surname_or_proper_noun(entry['meanings']):
            return entry
    
    # If all entries are surnames/proper nouns, return the first one
    return entries[0]

# Manual definitions for common words not in dictionary or with special meanings
# These override CC-CEDICT when the dictionary entry is not ideal for HSK learners
MANUAL_DEFINITIONS = {
    '喂': {'pinyin': 'wèi', 'meanings': ['hello (on the phone)', 'hey', 'to feed']},
    '打篮球': {'pinyin': 'dǎ lán qiú', 'meanings': ['to play basketball']},
    '踢足球': {'pinyin': 'tī zú qiú', 'meanings': ['to play soccer/football']},
    '虽然……但是……': {'pinyin': 'suī rán ... dàn shì ...', 'meanings': ['although... but...']},
    '不但……而且……': {'pinyin': 'bù dàn ... ér qiě ...', 'meanings': ['not only... but also...']},
    '一边……一边……': {'pinyin': 'yī biān ... yī biān ...', 'meanings': ['while... at the same time...']},
    '因为……所以……': {'pinyin': 'yīn wèi ... suǒ yǐ ...', 'meanings': ['because... therefore...']},
    '又……又……': {'pinyin': 'yòu ... yòu ...', 'meanings': ['both... and...']},
    '越……越……': {'pinyin': 'yuè ... yuè ...', 'meanings': ['the more... the more...']},
    '除了……以外': {'pinyin': 'chú le ... yǐ wài', 'meanings': ['except for...', 'besides...']},
    '要是……就……': {'pinyin': 'yào shi ... jiù ...', 'meanings': ['if... then...']},
    '先……然后……': {'pinyin': 'xiān ... rán hòu ...', 'meanings': ['first... then...']},
    '一……就……': {'pinyin': 'yī ... jiù ...', 'meanings': ['as soon as...']},
    '只要……就……': {'pinyin': 'zhǐ yào ... jiù ...', 'meanings': ['as long as... then...']},
    # Common words where CC-CEDICT first entry is not ideal
    '长': {'pinyin': 'cháng', 'meanings': ['long', 'length', 'strong point']},
    '得': {'pinyin': 'de', 'meanings': ['(structural particle)', 'to obtain', 'to get']},
    '等': {'pinyin': 'děng', 'meanings': ['to wait', 'etc.', 'class; rank']},
    '对': {'pinyin': 'duì', 'meanings': ['correct', 'right', 'towards']},
    '过': {'pinyin': 'guò', 'meanings': ['to pass', 'to cross', '(experiential particle)']},
    '还': {'pinyin': 'hái', 'meanings': ['still', 'also', 'yet']},
    '地': {'pinyin': 'de', 'meanings': ['(adverbial particle)', 'ground', 'earth']},
    '着': {'pinyin': 'zhe', 'meanings': ['(aspect particle)', 'to touch', 'to wear']},
    '吧': {'pinyin': 'ba', 'meanings': ['(modal particle)', '(suggestion)', 'bar (loanword)']},
    '坐': {'pinyin': 'zuò', 'meanings': ['to sit', 'to take a seat', 'to travel by']},
    '白': {'pinyin': 'bái', 'meanings': ['white', 'pure', 'blank']},
    '行': {'pinyin': 'xíng', 'meanings': ['to walk', 'OK', 'capable']},
    '会': {'pinyin': 'huì', 'meanings': ['can', 'to be able to', 'meeting']},
    '了': {'pinyin': 'le', 'meanings': ['(completed action marker)', 'to finish', 'to understand']},
    '的': {'pinyin': 'de', 'meanings': ['(possessive particle)', 'of', 'really and truly']},
    '就': {'pinyin': 'jiù', 'meanings': ['then', 'just', 'only']},
    '都': {'pinyin': 'dōu', 'meanings': ['all', 'both', 'even']},
    '和': {'pinyin': 'hé', 'meanings': ['and', 'with', 'harmony']},
    '在': {'pinyin': 'zài', 'meanings': ['at', 'in', 'to exist']},
    '是': {'pinyin': 'shì', 'meanings': ['to be', 'yes', 'correct']},
    '有': {'pinyin': 'yǒu', 'meanings': ['to have', 'there is', 'to exist']},
    '不': {'pinyin': 'bù', 'meanings': ['not', 'no']},
    '这': {'pinyin': 'zhè', 'meanings': ['this', 'these']},
    '那': {'pinyin': 'nà', 'meanings': ['that', 'those', 'then']},
    '他': {'pinyin': 'tā', 'meanings': ['he', 'him']},
    '她': {'pinyin': 'tā', 'meanings': ['she', 'her']},
    '我': {'pinyin': 'wǒ', 'meanings': ['I', 'me', 'my']},
    '你': {'pinyin': 'nǐ', 'meanings': ['you']},
    '们': {'pinyin': 'men', 'meanings': ['(plural marker for pronouns)']},
    '什么': {'pinyin': 'shén me', 'meanings': ['what?', 'something', 'anything']},
    '怎么': {'pinyin': 'zěn me', 'meanings': ['how?', 'what?', 'why?']},
    '为什么': {'pinyin': 'wèi shén me', 'meanings': ['why?', 'for what reason?']},
    '哪': {'pinyin': 'nǎ', 'meanings': ['which?', 'how']},
    '谁': {'pinyin': 'shéi', 'meanings': ['who?', 'someone']},
    '多少': {'pinyin': 'duō shao', 'meanings': ['how much?', 'how many?', 'number']},
    '几': {'pinyin': 'jǐ', 'meanings': ['how many?', 'several', 'a few']},
    '能': {'pinyin': 'néng', 'meanings': ['can', 'to be able to', 'ability']},
    '可以': {'pinyin': 'kě yǐ', 'meanings': ['can', 'may', 'possible']},
    '想': {'pinyin': 'xiǎng', 'meanings': ['to think', 'to want', 'to miss']},
    '要': {'pinyin': 'yào', 'meanings': ['to want', 'will', 'need']},
    '去': {'pinyin': 'qù', 'meanings': ['to go', 'to leave']},
    '来': {'pinyin': 'lái', 'meanings': ['to come', 'to arrive']},
    '看': {'pinyin': 'kàn', 'meanings': ['to see', 'to look at', 'to watch']},
    '听': {'pinyin': 'tīng', 'meanings': ['to listen', 'to hear', 'to obey']},
    '说': {'pinyin': 'shuō', 'meanings': ['to speak', 'to say', 'to talk']},
    '读': {'pinyin': 'dú', 'meanings': ['to read', 'to study']},
    '写': {'pinyin': 'xiě', 'meanings': ['to write']},
    '吃': {'pinyin': 'chī', 'meanings': ['to eat', 'to consume']},
    '喝': {'pinyin': 'hē', 'meanings': ['to drink']},
    '做': {'pinyin': 'zuò', 'meanings': ['to do', 'to make', 'to produce']},
    '工作': {'pinyin': 'gōng zuò', 'meanings': ['to work', 'job', 'work']},
    '学习': {'pinyin': 'xué xí', 'meanings': ['to learn', 'to study']},
    '喜欢': {'pinyin': 'xǐ huan', 'meanings': ['to like', 'to be fond of']},
    '知道': {'pinyin': 'zhī dào', 'meanings': ['to know', 'to be aware of']},
    '认识': {'pinyin': 'rèn shi', 'meanings': ['to know', 'to recognize', 'to be familiar with']},
    '觉得': {'pinyin': 'jué de', 'meanings': ['to think', 'to feel']},
    '希望': {'pinyin': 'xī wàng', 'meanings': ['to hope', 'to wish', 'hope']},
    '帮助': {'pinyin': 'bāng zhù', 'meanings': ['to help', 'assistance', 'aid']},
    '开始': {'pinyin': 'kāi shǐ', 'meanings': ['to begin', 'to start', 'beginning']},
    '结束': {'pinyin': 'jié shù', 'meanings': ['to end', 'to finish', 'to conclude']},
    '准备': {'pinyin': 'zhǔn bèi', 'meanings': ['to prepare', 'to get ready', 'preparation']},
    '回答': {'pinyin': 'huí dá', 'meanings': ['to answer', 'to reply', 'answer']},
    '问': {'pinyin': 'wèn', 'meanings': ['to ask', 'to inquire']},
    '告诉': {'pinyin': 'gào su', 'meanings': ['to tell', 'to inform', 'to let know']},
    '给': {'pinyin': 'gěi', 'meanings': ['to give', 'for', 'to']},
    '让': {'pinyin': 'ràng', 'meanings': ['to let', 'to allow', 'to make']},
    '把': {'pinyin': 'bǎ', 'meanings': ['(object marker)', 'to hold', 'handle']},
    '被': {'pinyin': 'bèi', 'meanings': ['(passive marker)', 'by', 'quilt']},
    '从': {'pinyin': 'cóng', 'meanings': ['from', 'since', 'through']},
    '向': {'pinyin': 'xiàng', 'meanings': ['towards', 'to face', 'direction']},
    '离': {'pinyin': 'lí', 'meanings': ['from', 'away from', 'to leave']},
    '跟': {'pinyin': 'gēn', 'meanings': ['with', 'and', 'to follow']},
    '比': {'pinyin': 'bǐ', 'meanings': ['to compare', 'than', 'ratio']},
}

def create_word_entry(word, cedict):
    """Create a word entry in the app's expected format."""
    # Check manual definitions first
    if word in MANUAL_DEFINITIONS:
        manual = MANUAL_DEFINITIONS[word]
        return {
            'simplified': word,
            'forms': [{
                'transcriptions': {
                    'pinyin': manual['pinyin']
                },
                'meanings': manual['meanings']
            }]
        }
    
    # Look up in CC-CEDICT
    if word in cedict:
        dict_entry = get_best_entry(cedict[word])
        if dict_entry:
            pinyin_with_tones = convert_pinyin_to_tone_marks(dict_entry['pinyin'])
            meanings = dict_entry['meanings'][:3] if dict_entry['meanings'] else ['(no definition available)']
            
            return {
                'simplified': word,
                'forms': [{
                    'transcriptions': {
                        'pinyin': pinyin_with_tones
                    },
                    'meanings': meanings
                }]
            }
    
    # Fallback to pypinyin
    pinyin_str = get_pinyin_with_tones(word)
    
    # Try to build meaning from individual characters
    meanings = []
    if len(word) > 1:
        char_meanings = []
        for char in word:
            if char in cedict:
                entry = get_best_entry(cedict[char])
                if entry and entry['meanings']:
                    short_meaning = entry['meanings'][0].split(';')[0].split(',')[0]
                    char_meanings.append(short_meaning)
        if char_meanings:
            meanings = [' + '.join(char_meanings)]
    
    if not meanings:
        meanings = ['(no definition available)']
    
    return {
        'simplified': word,
        'forms': [{
            'transcriptions': {
                'pinyin': pinyin_str
            },
            'meanings': meanings
        }]
    }

def main():
    # Load CC-CEDICT dictionary
    print("Loading CC-CEDICT dictionary...")
    cedict = load_cedict('cedict_ts.u8')
    print(f"Loaded {len(cedict)} entries from CC-CEDICT")
    
    # Excel file path
    excel_path = 'hsk_levels/HSK-2012.xls'
    
    # HSK levels to process (1, 2, 3 for now as those are the ones in the app)
    hsk_sheets = {
        1: 'HSK（一级）（150）',
        2: 'HSK（二级）（300）',
        3: 'HSK（三级）（600）',
    }
    
    for level, sheet_name in hsk_sheets.items():
        print(f"\nProcessing HSK Level {level}...")
        
        # Extract words from Excel
        words = extract_hsk_words(excel_path, sheet_name)
        print(f"Found {len(words)} unique words in HSK {level}")
        
        # Create word entries
        word_entries = []
        missing_meanings = []
        
        for word in words:
            entry = create_word_entry(word, cedict)
            word_entries.append(entry)
            
            meanings = entry['forms'][0]['meanings']
            if not meanings or meanings == ['(no definition available)']:
                missing_meanings.append(word)
        
        # Save to JSON
        output_path = f'HanziFive/hsk_levels/HSK{level}.json'
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(word_entries, f, ensure_ascii=False, indent=2)
        
        print(f"Saved {len(word_entries)} words to {output_path}")
        
        if missing_meanings:
            print(f"Warning: {len(missing_meanings)} words missing meanings:")
            for w in missing_meanings[:20]:
                print(f"  - {w}")
            if len(missing_meanings) > 20:
                print(f"  ... and {len(missing_meanings) - 20} more")

if __name__ == '__main__':
    main()
