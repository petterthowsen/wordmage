module WordMage::IPA
    ## The category of a phoneme
    enum Category
        VOWEL
        CONSONANT
    end
    
    ## A phoneme
    ## extended by WordMage::IPA::Vowel and WordMage::IPA::Consonant
    class Phoneme
        include JSON::Serializable
        
        ## The phonetic symbol
        property symbol : String
        
        ## The most common romanized form
        property romanization : String

        ## The category of the phoneme
        property category : Category

        def initialize(@symbol : String, @romanization : String, @category : Category)
        end

        ## Returns the phoneme symbol
        def to_s(io : IO) : Nil
            io << symbol
        end

        ## Returns the phoneme symbol
        def to_s : String
            symbol
        end

        ## Returns a human-readable name describing the phoneme
        ## This method should be overridden by subclasses to provide detailed descriptions
        def name : String
            "#{symbol} (#{category.to_s.downcase})"
        end
    end
end