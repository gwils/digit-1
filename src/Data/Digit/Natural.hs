module Data.Digit.Natural
  ( _NaturalDigits
  , naturalToDigits
  , digitsToNatural
  ) where

import           Prelude             (Int, error, fromIntegral, maxBound, (*),
                                      (+), (-), (>), (^))

import           Control.Category    ((.))
import           Control.Lens        (Prism', ifoldrM, prism', ( # ))

import           Data.Foldable       (length)
import           Data.Function       (($))
import           Data.Functor        (fmap, (<$>))
import           Data.Semigroup      ((<>))

import           Data.List           (replicate)

import           Data.List.NonEmpty  (NonEmpty ((:|)))
import qualified Data.List.NonEmpty  as NE

import           Data.Maybe          (Maybe (..))

import           Data.Digit.Digit
import           Data.Digit.Integral (integralDecimal)

import           Numeric.Natural     (Natural)

import           Data.Scientific     (toDecimalDigits)

-- |
--
-- >>> _NaturalDigits # 0
-- 0 :| []
--
-- >>> _NaturalDigits # 1
-- 1 :| []
--
-- >>> _NaturalDigits # 9223372036854775807
-- 9 :| [2,2,3,3,7,2,0,3,6,8,5,4,7,7,5,8,0,7]
--
-- >>> (9 :| [2,2,3,3,7,2,0,3,6,8,5,4,7,7,5,8,0,7]) ^? _NaturalDigits
-- Just 9223372036854775807
--
-- >>> (1 :| []) ^? _NaturalDigits
-- Just 1
--
-- prop> \x -> digitsToNatural ( naturalToDigits x ) == Just x
--
_NaturalDigits :: Prism' (NonEmpty Digit) Natural
_NaturalDigits = prism' naturalToDigits digitsToNatural

-- | NonEmpty Digits from a Natural number
--
-- >>> naturalDigits 0
-- 0 :| []
--
-- >>> naturalDigits 9
-- 9 :| []
--
-- >>> naturalDigits 393564
-- 3 :| [9,3,5,6,4]
--
-- >>> naturalDigits 9223372036854775807
-- 9 :| [2,2,3,3,7,2,0,3,6,8,5,4,7,7,5,8,0,7]
--
naturalToDigits :: Natural -> NonEmpty Digit
naturalToDigits n =
  case toDecimalDigits $ fromIntegral n of
    -- toDecimalDigits :: n -> ([n],n)
    -- toDecimalDigits 0    = ([0],0)
    -- toDecimalDigits (-0) = ([0],0)
    -- toDecimalDigits (-1) = ([-1],1)
    ([],   _  ) -> error "Data.Scientific.toDecimalDigits is no longer correct!"
    (x:xs, eXP) -> g x :| (g <$> xs) <> t (x:xs) eXP

  where
    t allDigs eXP =
      replicate (eXP - length allDigs) Digit0

    -- EWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW!
    -- But you can't reach this point unless you have a non-zero absolute integral value. So... I dunno.
    g 0 = Digit0
    g 1 = Digit1
    g 2 = Digit2
    g 3 = Digit3
    g 4 = Digit4
    g 5 = Digit5
    g 6 = Digit6
    g 7 = Digit7
    g 8 = Digit8
    g 9 = Digit9
    g _ = error "The universe now has more than ten digits."

-- | Create a number from a list of digits with the integer bounds of the machine.
--
-- >>> naturalFromDigits (D.x3 :| [D.x4])
-- Just 34
--
-- >>> naturalFromDigits (D.Digit3 :| [D.Digit9,D.Digit3,D.Digit5,D.Digit6,D.Digit4])
-- Just 393564
--
-- >>> naturalFromDigits (D.x0 :| [])
-- Just 0
--
-- Int maxBound for Int64
-- >>> naturalFromDigits (D.x9 :| [D.x2,D.x2,D.x3,D.x3,D.x7,D.x2,D.x0,D.x3,D.x6,D.x8,D.x5,D.x4,D.x7,D.x7,D.x5,D.x8,D.x0,D.x7])
-- Just 9223372036854775807
--
-- Int maxBound + 1 for Int64
-- >>> naturalFromDigits (D.x9 :| [D.x2,D.x2,D.x3,D.x3,D.x7,D.x2,D.x0,D.x3,D.x6,D.x8,D.x5,D.x4,D.x7,D.x7,D.x5,D.x8,D.x0,D.x8])
-- Nothing
--
digitsToNatural :: NonEmpty Digit -> Maybe Natural
digitsToNatural = fmap fromIntegral . ifoldrM f 0 . NE.reverse
  where
    f :: Int -> Digit -> Int -> Maybe Int
    f i d curr =
      let
        next = (integralDecimal # d) * (10 ^ i)
      in
        if curr > maxBound - next
        then Nothing
        else Just (curr + next)
