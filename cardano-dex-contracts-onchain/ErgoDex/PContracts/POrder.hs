{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE UndecidableInstances #-}

module ErgoDex.PContracts.POrder (
    OrderRedeemer (..),
    OrderAction (..),
) where

import qualified GHC.Generics as GHC
import Generics.SOP (Generic, I (I))

import Plutarch
import Plutarch.Builtin (pasInt, pforgetData)
import Plutarch.DataRepr (DerivePConstantViaData (..), PDataFields, PIsDataReprInstances (..))
import Plutarch.Lift
import Plutarch.Prelude
import Plutarch.Unsafe (punsafeCoerce)

import qualified ErgoDex.Contracts.Proxy.Order as O

data OrderAction (s :: S) = Apply | Refund

instance PIsData OrderAction where
    pfromData tx =
        let x = pasInt # pforgetData tx
         in pmatch' x pcon
    pdata x = pmatch x (punsafeCoerce . pdata . pcon')

instance PlutusType OrderAction where
    type PInner OrderAction _ = PInteger

    pcon' Apply = 0
    pcon' Refund = 1

    pmatch' x f =
        pif (x #== 0) (f Apply) (f Refund)

newtype OrderRedeemer (s :: S)
    = OrderRedeemer
        ( Term
            s
            ( PDataRecord
                '[ "poolInIx" ':= PInteger
                 , "orderInIx" ':= PInteger
                 , "rewardOutIx" ':= PInteger
                 , "action" ':= OrderAction
                 ]
            )
        )
    deriving stock (GHC.Generic)
    deriving anyclass (Generic, PIsDataRepr)
    deriving
        (PMatch, PIsData, PDataFields, PlutusType)
        via PIsDataReprInstances OrderRedeemer

instance PUnsafeLiftDecl OrderRedeemer where type PLifted OrderRedeemer = O.OrderRedeemer
deriving via (DerivePConstantViaData O.OrderRedeemer OrderRedeemer) instance (PConstant O.OrderRedeemer)
