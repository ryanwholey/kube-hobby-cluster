const execSync = require('child_process').execSync

const types = [
    'loadbalancer',
    'master',
    'worker',
]

function getIpsForType(type) {
    return execSync(`cd terraform && terraform output ${type}_instance_ips`)
        .toString('utf8')
        .split('\n')
        .filter(i => !!i)
        .map((i) => i.replace(/\,/,''))
}

function getName(type, index) {
    if (type === 'loadbalancer') {
        return `loadbalancer-${index}`
    } else {
        return `kube-${type}-${index}`
    }
}

function addAnsibleProps(ipMap) {
    return Object.keys(ipMap).reduce((map, type) => ({
        ...map,
        [`${type}s`]: ipMap[type].map((ip, index) => ({
            ansible_user: 'ubuntu',
            name: getName(type, index + 1),
            ansible_host: ip,
        }))
    }), {})
}

function main() {
    const ipMap = types.reduce((ips, type) => ({
        ...ips,
        [type]: getIpsForType(type),
    }), {})

    return addAnsibleProps(ipMap)
}

module.exports = main