# 🏦 KipuBank - Análisis de Seguridad

![Solidity](https://img.shields.io/badge/Solidity-0.8.30-blue.svg?logo=ethereum) ![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg) ![Network](https://img.shields.io/badge/network-Sepolia-purple.svg)

Protocolo bancario descentralizado con soporte para **ETH**, **USDC** y **swaps de tokens ERC20** vía Uniswap V2, utilizando oráculos Chainlink para conversión de precios.

---

## ✨ Mejoras Implementadas

| Mejora | Beneficio | Impacto |
|--------|-----------|---------|
| **Oráculos Chainlink** | Conversión ETH→USD en tiempo real | Límites consistentes independientes de volatilidad |
| **Integración Uniswap V2** | Depósitos en cualquier token ERC20 | Mayor liquidez y UX mejorada |
| **Sistema de Roles** | Separación de responsabilidades administrativas | Reduce riesgo de compromiso de clave única |
| **ReentrancyGuard** | Protección contra ataques de reentrancy | Previene vector crítico de ataque |
| **Pausable** | Respuesta rápida ante emergencias | Control de crisis sin pérdida de fondos |

---

## 🏗️ Arquitectura

```solidity
// Estructura multi-vault por usuario
mapping(address token => mapping(address holder => uint256)) private s_balances;

// address(0)      → Balance en ETH
// address(i_usdc) → Balance en USDC
// Otros tokens    → Conversión inmediata a USDC (no se almacenan)
```

**Flujo de precios:** ETH → Chainlink Oracle → Verificaciones (HEARTBEAT + price > 0) → Conversión USD

---

## ⚠️ Análisis de Amenazas

### 🔴 Vulnerabilidades Críticas

#### 1. **Centralización Excesiva**
**Severidad:** Alta  
**Problema:** Owner puede pausar indefinidamente y cambiar oráculo sin timelock.

```solidity
// Mitigación recomendada
uint256 constant TIMELOCK_DELAY = 2 days;
mapping(bytes32 => uint256) public pendingActions;
```

#### 2. **Falta de Circuit Breaker en Swaps**
**Severidad:** Media  
**Problema:** No hay límite de volumen por bloque, permitiendo manipulación de precio.

```solidity
// Mitigación
uint256 public constant MAX_SWAP_PER_BLOCK = 100_000 * 1e6;
mapping(uint256 => uint256) public swapVolumePerBlock;
```

#### 3. **Race Condition en `s_totalContract`**
**Severidad:** Media  
**Problema:** Doble verificación del límite global en `depositToken()` puede fallar si otro usuario deposita entre checks.

```solidity
// Línea 430-431: Primera verificación
if(amounts[amounts.length -1] + s_totalContract > i_bankCap) revert;

// Línea 440: Segunda verificación (puede fallar por race condition)
if(amountsToSwap[amountsToSwap.length - 1] + s_totalContract > i_bankCap) revert;
```

#### 4. **Sin Protección de Slippage en Depósitos ETH**
**Severidad:** Media-Baja  
**Problema:** Usuario no puede especificar mínimo USD esperado por su ETH.

```solidity
// Mitigación
function depositETH(uint256 _minUSD) external payable {
    uint256 amountUSD = convertEthInUSD(msg.value);
    require(amountUSD >= _minUSD, "Slippage");
}
```

#### 5. **Acumulación de Allowances**
**Severidad:** Baja  
**Problema:** `safeIncreaseAllowance` sin reset puede acumular permisos excesivos.

```solidity
// Línea 418
IERC20(_tokenIn).safeIncreaseAllowance(address(ROUTER), _amountIn);
// Debería verificar allowance actual primero
```

---

### ✅ Protecciones Implementadas

| Vector | Mitigación |
|--------|------------|
| Reentrancy | `nonReentrant` + CEI pattern |
| Integer Overflow | Solidity 0.8.30 |
| Access Control | `Ownable` + `AccessControl` |
| Oracle Manipulation | HEARTBEAT (3600s) + validación `price > 0` |
| Frontrunning | `deadline` + `amountOutMin` en swaps |

---

## 📊 Cobertura de Pruebas

**Actual: 75%**

### ✅ Tests Implementados
- Deposit/Withdraw ETH y USDC
- Swap de tokens
- Pause/Unpause
- Whitelist management
- Transfer ownership

---

## 🚀 Despliegue

### Parámetros Constructor (Sepolia)

```solidity
constructor(
    1_000_000 * 1e6,  // Límite: 1M USD
    10_000 * 1e6,     // Threshold: 10k USD
    msg.sender,       // Owner
    0x694AA1769357215DE4FAC081bf1f309aDC325306,  // ETH/USD Feed
    0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238,  // USDC
    0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008   // Uniswap Router
)
```

### Deploy con Foundry

```bash
# Compilar
forge build

# Testear
forge test -vvv

# Desplegar en Sepolia
forge create src/KipuBank.sol:KipuBank \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --broadcast
```
---
## Interacciones

## 1️⃣ Variables de entorno

```bash
export BANK_ADDRESS="0xbE1ac936e23b392aBb3652b435A178A693BB0959"
export DAI_ADDRESS="0x3e622317f8C93f7328350cF0B56d9eD4C620C5d6"
export USDC_ADDRESS="0x694AA1769357215DE4FAC081bf1f309aDC325306"

export PRIVATE_KEY="TU_CLAVE_PRIVADA"
export SEPOLIA_RPC="https://sepolia.infura.io/v3/TU_INFURA_KEY"
```
---


### Deposito Eth
```bash
cast send $BANK_ADDRESS "depositETH()" --value $(cast to-wei 1 ether) --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC
```
---
### Deposito USDC

```bash
# Aprobar USDC
cast send $USDC_ADDRESS "approve(address,uint256)" $BANK_ADDRESS $(cast to-wei 1000 6) --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC

# Depositar USDC
cast send $BANK_ADDRESS "depositUSDC(uint256)" $(cast to-wei 1000 6) --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC
```
---
### Deposito Token ERC20 (en este caso DAI, de modo de ejemplo)

### Aprobar DAI

```bash 
cast send $DAI_ADDRESS "approve(address,uint256)" $BANK_ADDRESS $(cast to-wei 100 ether) --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC`
```

### Depositar con swap
```bash
DEADLINE=$(( $(date +%s) + 300 ))
cast send $BANK_ADDRESS "depositToken(uint256,uint256,address,uint256)" \
    $(cast to-wei 100 ether) $(cast to-wei 98 6) $DAI_ADDRESS $DEADLINE \
    --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC
```
---
### Retirar ETH
```bash
cast send $BANK_ADDRESS "withdrawETH(uint256)" $(cast to-wei 0.5 ether) --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC
```
---
### Retirar USDC
```bash
cast send $BANK_ADDRESS "withdrawUSDC(uint256)" $(cast to-wei 500 6) --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC
```
---

## 🎯 Decisiones de Diseño

### 1. Conversión Inmediata a USDC
- ✅ **Pro:** Simplifica contabilidad (solo 2 balances por usuario)
- ✅ **Pro:** Reduce superficie de ataque
- ❌ **Contra:** Usuario no puede retirar token original
- ❌ **Contra:** Usuario asume slippage inmediatamente

### 2. Límites en USD, No en ETH
- ✅ **Pro:** Consistencia independiente de volatilidad
- ✅ **Pro:** Límites predecibles para usuarios
- ❌ **Contra:** Dependencia total del oráculo

### 3. `receive()`/`fallback()` Bloqueados
- ✅ **Pro:** Previene depósitos accidentales
- ✅ **Pro:** Evita desincronización de `s_totalContract`
- ❌ **Contra:** Contrato no puede recibir ETH de otros contratos

### 4. Double-Check en Swaps
- ✅ **Pro:** Seguridad robusta contra race conditions
- ✅ **Pro:** Previene exceder límites
- ❌ **Contra:** Puede fallar inesperadamente bajo alta concurrencia
- ❌ **Contra:** ~5k gas adicional

### 5. Threshold Solo en Retiros
- ✅ **Pro:** Incentiva depósitos grandes
- ✅ **Pro:** Previene "bank runs"
- ❌ **Contra:** Usuarios grandes deben fragmentar retiros

---

## 🛣️ Roadmap de Madurez

### Fase 1: Seguridad Avanzada
- [ ] Timelock (48h) para cambios críticos
- [ ] Multisig ownership (3/5 Gnosis Safe)
- [ ] Circuit breaker dinámico por bloque
- [ ] Oráculo fallback secundario
- [ ] Rate limiting por usuario

### Fase 2: Upgradeability
- [ ] Migrar a UUPS Proxy Pattern
- [ ] Storage gaps para futuras versiones
- [ ] Sistema de versionado

### Fase 3: Auditorías
- [ ] Auditoría externa (CertiK/OpenZeppelin/Trail of Bits)
- [ ] Bug bounty program (Immunefi)
- [ ] Formal verification de funciones críticas
- [ ] Cobertura de tests >95%

### Fase 4: Optimizaciones
- [ ] Packed storage (uint128 para balances)
- [ ] Batch operations para múltiples transacciones
- [ ] Optimización de gas en loops

---

## 📈 Métricas de Madurez

| Métrica | Actual | Objetivo | Status |
|---------|--------|----------|--------|
| Cobertura de tests | 75% | 95% | 🟡 |
| Auditorías completadas | 0 | 2+ | 🔴 |
| Timelock en funciones críticas | No | Sí | 🔴 |
| Multisig ownership | No | Sí | 🔴 |
| Circuit breakers | No | Sí | 🔴 |
| Oráculo redundante | No | Sí | 🟡 |

---

## 📍 Contrato Verificado

**Sepolia:** [`0xbE1ac936e23b392aBb3652b435A178A693BB0959`](https://sepolia.etherscan.io/address/0xbE1ac936e23b392aBb3652b435A178A693BB0959)

---

## ⚖️ Licencia

MIT © 2025 — Facundo Alejandro Caniza

---

> 💬 *"La confianza no se delega, se codifica." — KipuBank*
