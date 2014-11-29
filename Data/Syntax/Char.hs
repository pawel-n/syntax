{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{- |
Module      :  Data.Syntax.Char
Description :  Char specific combinators.
Copyright   :  (c) Paweł Nowak
License     :  MIT

Maintainer  :  Paweł Nowak <pawel834@gmail.com>
Stability   :  experimental

Common combinators that work with sequences of chars.

-}
module Data.Syntax.Char (
    SyntaxChar(..),
    SyntaxText,
    signed,
    spaces,
    spaces_,
    spaces1,
    endOfLine,
    digitDec,
    digitOct,
    digitHex
    ) where

import Control.Lens.SemiIso
import Data.Char
import Data.MonoTraversable
import Data.Scientific (Scientific)
import Data.SemiIsoFunctor
import Data.Syntax
import Data.Syntax.Combinator
import Data.Text (Text)

-- | Syntax constrainted to sequences of chars.
--
-- Note: methods of this class do not have default implementations (for now), 
-- because their code is quite ugly and already written in most parser libraries.
class (Syntax syn seq, Element seq ~ Char) => SyntaxChar syn seq where
    -- | An unsigned decimal number.
    decimal :: Integral a => syn a

    -- | A scientific number.
    scientific :: syn Scientific

    {-# MINIMAL decimal, scientific #-}

-- | An useful synonym for SyntaxChars with Text sequences.
type SyntaxText syn = SyntaxChar syn Text

-- | A number with an optional leading '+' or '-' sign character.
signed :: (Real a, SyntaxChar syn seq) => syn a -> syn a
signed n =  _Negative /$/ char '-' */ n
        /|/ opt_ (char '+') */ n

-- | Accepts zero or more spaces. Generates a single space.
spaces :: SyntaxChar syn seq => syn ()
spaces = opt spaces1

-- | Accepts zero or more spaces. Generates no output.
spaces_ :: SyntaxChar syn seq => syn ()
spaces_ = opt_ spaces1

-- | Accepts one or more spaces. Generates a single space.
spaces1 :: SyntaxChar syn seq => syn ()
spaces1 = constant (opoint ' ') /$/ takeWhile1 isSpace

-- | Accepts a single newline. Generates a newline.
endOfLine :: SyntaxChar syn seq => syn ()
endOfLine = char '\n'

-- | A decimal digit.
digitDec :: SyntaxChar syn seq => syn Int
digitDec = semiIso toChar toInt /$/ anyChar
  where toInt c | isDigit c = Right (digitToInt c)
                | otherwise = Left ("Expected a decimal digit, got " ++ [c])
        toChar i | i >= 0 && i <= 9 = Right (intToDigit i)
                 | otherwise        = Left ("Expected a decimal digit, got number " ++ show i)

-- | An octal digit.
digitOct :: SyntaxChar syn seq => syn Int
digitOct = semiIso toChar toInt /$/ anyChar
  where toInt c | isOctDigit c = Right (digitToInt c)
                | otherwise    = Left ("Expected an octal digit, got " ++ [c])
        toChar i | i >= 0 && i <= 7 = Right (intToDigit i)
                 | otherwise        = Left ("Expected an octal digit, got number " ++ show i)

-- | A hex digit.
digitHex :: SyntaxChar syn seq => syn Int
digitHex = semiIso toChar toInt /$/ anyChar
  where toInt c | isHexDigit c = Right (digitToInt c)
                | otherwise    = Left ("Expected a hex digit, got " ++ [c])
        toChar i | i >= 0 && i <= 15 = Right (intToDigit i)
                 | otherwise         = Left ("Expected a hex digit, got number " ++ show i)
