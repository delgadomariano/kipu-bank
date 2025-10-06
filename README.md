# KipuBank: Smart Contract de Banca Descentralizada

## 📜 Descripción del Contrato

**KipuBank** es un contrato inteligente simple construido en **Solidity** que simula un sistema bancario descentralizado. Permite a los usuarios depositar tokens nativos (ETH) en bóvedas personales y retirarlos, pero con la imposición de límites de seguridad clave.

### Características Clave

1.  **Límite Global (Bank Cap):** El contrato tiene un límite total de ETH que puede albergar (`i_bankCap`), definido en el despliegue.
2.  **Límite de Retiro por Transacción:** Se impone un umbral máximo por cada retiro individual (`i_withdrawalLimitPerTx`) para mitigar el riesgo de grandes extracciones.
3.  **Seguridad:** El contrato sigue el patrón **checks-effects-interactions** y utiliza **errores personalizados** para todas las condiciones de `revert`.
4.  **Registro:** Mantiene un registro del número total de depósitos y retiros.

---

## 🚀 Instrucciones de Despliegue

El contrato **KipuBank** requiere dos parámetros de constructor: `bankCap_` y `withdrawalLimitPerTx_`, ambos en unidades **wei**.

### Parámetros del Constructor

| Parámetro | Tipo | Descripción | Ejemplo (para 10 ETH) |
| :--- | :--- | :--- | :--- |
| `bankCap_` | `uint256` | Límite máximo total de ETH que puede contener el banco (en wei). | `10000000000000000000` (10 Ether) |
| `withdrawalLimitPerTx_` | `uint256` | Límite máximo de retiro por transacción (en wei). | `1000000000000000000` (1 Ether) |

### Pasos para el Despliegue (usando Remix o Hardhat)

1.  **Compilación:** Compila `KipuBank.sol` con la versión `0.8.20` o superior de Solidity.
2.  **Configuración del Entorno:** Conéctate a la testnet de tu elección (e.g., Sepolia, Goerli).
3.  **Inyección de Parámetros:**
    * Ingresa los valores deseados para `bankCap_` y `withdrawalLimitPerTx_` en el campo del constructor.
    * *Ejemplo:* `10000000000000000000, 1000000000000000000`
4.  **Transacción de Despliegue:** Envía la transacción y espera la confirmación.

---

## 🤝 Cómo Interactuar con el Contrato

Aquí se describen las funciones clave y su uso:

### 1. Depositar ETH

* **Función:** `deposit()`
* **Tipo:** `external payable`
* **Uso:** Envía ETH al contrato a través de esta función. El monto enviado se asignará automáticamente al saldo personal de `msg.sender`.
* **Restricción:** Fallará si el depósito excede el `i_bankCap` o si se intenta depositar 0 ETH.

### 2. Retirar ETH

* **Función:** `withdraw(uint256 amount)`
* **Tipo:** `external`
* **Parámetro:** `amount` (la cantidad de wei a retirar).
* **Restricciones:**
    * Debe ser menor o igual al `i_withdrawalLimitPerTx`.
    * Debe ser menor o igual al saldo personal del usuario.
    * Fallará si la transferencia de ETH falla o si se intenta retirar 0 ETH.

### 3. Consultar Saldo

* **Función:** `getBalance(address user)`
* **Tipo:** `external view`
* **Parámetro:** `user` (la dirección de la cuenta a consultar).
* **Retorno:** El saldo del usuario en wei.

### 4. Consultar Contadores

* **Función:** `getDepositCount()`
* **Función:** `getWithdrawalCount()`
* **Tipo:** `external view`
* **Retorno:** El número total de depósitos o retiros exitosos realizados en el contrato.

---

## 🔗 Dirección del Contrato Desplegado
 

| Testnet | Dirección del Contrato | Enlace al Block Explorer |
| :--- | :--- | :--- |
| Sepolia | https://sepolia.etherscan.io/tx/0xfacd97e21e39ed921af22cab658fec5d16deb487085431a8655c3b88d05d237d | https://eth-sepolia.blockscout.com/tx/0xfacd97e21e39ed921af22cab658fec5d16deb487085431a8655c3b88d05d237d |